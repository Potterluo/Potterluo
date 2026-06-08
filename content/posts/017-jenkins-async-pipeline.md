---
title: "Jenkins 流水线异步调用与跨流水线通信完全指南"
date: 2026-06-08T14:00:00+08:00
draft: false
tags: [Jenkins, CI/CD, Pipeline, Groovy, DevOps, 异步编程]
categories: [技术分享]
---

## 引言：为什么需要异步调用？

在日常的 CI/CD 实践中，我们经常会遇到这样的场景：一个主流水线需要触发多个下游流水线，但又不想被它们阻塞。比如：

- 触发自动化测试后，主流水线想继续做其他准备工作，而不是傻等测试结束
- 同时启动多个环境的部署，让它们并行跑
- 触发一个长时间运行的性能测试，主流水线先去准备后续步骤

Jenkins 的 `build` 步骤默认是**同步调用**的 —— 设置了 `wait: true` 后，父流水线会一直等到下游流水线执行完毕才会继续。这在很多场景下并不理想。

那么，Jenkins 能不能异步调用别的流水线？答案是肯定的，而且方法不止一种。

## 方法一：`wait: false` —— 最简单的异步触发

这是最直接的方式。在 `build` 步骤中将 `wait` 参数设为 `false`，父流水线触发下游后会立即继续执行，不会等待结果：

```groovy
build(
    job: fullJobName,
    parameters: params,
    wait: false,           // 关键参数：设为 false 实现异步
    propagate: false       // 推荐设为 false，子流水线失败不影响父流水线
)
```

**注意事项：**

- 使用 `wait: false` 后，`build` 步骤**不再返回 `Run` 对象**，你无法通过返回值获取子流水线的状态
- 如果你只需要"触发并忘记"，这是最简单的做法
- 可以结合 `quietPeriod` 实现延迟触发：

```groovy
build(job: fullJobName, quietPeriod: 7200, wait: false)  // 延迟 2 小时后触发
```

## 方法二：`parallel` 并发执行

如果需要同时触发多个子流水线，可以使用 `parallel` 步骤并发执行，每个分支独立运行：

```groovy
stage('Trigger All Downstream') {
    parallel(
        'test-job': {
            build job: 'test-pipeline/main', wait: true, parameters: testParams
        },
        'deploy-job': {
            build job: 'deploy-pipeline/main', wait: true, parameters: deployParams
        }
    )
}
```

注意这里每个分支内部仍然用 `wait: true`（同步），但多个分支之间是**并行**的。如果你需要真正的"触发即走"，把各分支内的 `wait` 改为 `false` 即可。

## 方法三：通过 REST API 触发（跨实例场景）

当上游和下游不在同一个 Jenkins 实例时，可以使用 REST API：

```groovy
sh "curl -X POST ${JENKINS_URL}/job/${JOB_NAME}/buildWithParameters \
    --user ${CREDENTIALS} \
    --data 'PARAM1=value1&PARAM2=value2'"
```

这种方式适合跨 Jenkins 实例、跨团队的场景。

## 实战痛点：异步调用后能拿到产物吗？

一个常见的问题是：异步触发下游后，能不能立刻 `copyArtifacts` 复制下游的产物？

**答案是不能。**

`copyArtifacts` 需要从**已经完成**构建的 Job 中获取归档的产物（通常在 `post` 阶段或 `archiveArtifacts` 之后才会保存）。异步调用（`wait: false`）仅仅触发了下游，父流水线继续执行时下游可能刚进入队列，产物还不存在。

**如果你需要复制下游产物，有以下几种方式：**

### 方案 A：改用同步调用

```groovy
def result = build job: fullJobName, wait: true, parameters: params
// 下游已完成，直接复制产物
copyArtifacts projectName: fullJobName, selector: specific("${result.getNumber()}")
```

### 方案 B：异步触发 + 主动等待

```groovy
// 先触发
def result = build job: fullJobName, wait: true
// 在等待期间可以做其他不依赖产物的事
// ...

// 然后复制产物
copyArtifacts projectName: fullJobName, selector: specific("${result.getNumber()}")
```

### 方案 C：`parallel` + 同步等待多个下游

```groovy
stage('Trigger & Collect') {
    parallel(
        'job-a': {
            def r = build job: 'job-a', wait: true
            copyArtifacts projectName: 'job-a', selector: specific("${r.getNumber()}")
        },
        'job-b': {
            def r = build job: 'job-b', wait: true
            copyArtifacts projectName: 'job-b', selector: specific("${r.getNumber()}")
        }
    )
}
```

## 高级话题：下游流水线如何主动向父流水线回传信息？

当你采用异步模式时，下游流水线在执行过程中产生了重要信息（比如服务 URL、Pod 列表、日志目录），如何在**不等待下游完成**的情况下把这些信息回传给父流水线？

这里整理了 5 种主流方案：

### 方案一：共享变量（`buildVariables`）—— 最简单

如果下游是同步触发的，可以直接通过 `buildVariables` 获取：

```groovy
// 上游
def result = build job: 'downstream-job', wait: true
def data = result.buildVariables.RETURNED_VALUE

// 下游 pipeline 中设置
pipeline {
    environment {
        RETURNED_VALUE = ""  // 必须先在 environment 中声明
    }
    stages {
        stage('Generate Data') {
            steps {
                script {
                    env.RETURNED_VALUE = "这是下游生成的重要数据"
                }
            }
        }
    }
}
```

**限制：** 变量值只能是字符串，且需要同步等待。

### 方案二：共享存储 + 标记文件 —— 适合大信息量

下游在关键节点写入文件到共享目录：

```groovy
// 下游流水线
writeJSON file: '/shared/downstream_data.json', json: [url: env.SERVICE_URL, pods: podList]
sh 'touch /shared/downstream.ready'  // 标记文件，表示数据已写完
```

上游轮询读取：

```groovy
waitUntil {
    fileExists '/shared/downstream.ready'
}
def data = readJSON file: '/shared/downstream_data.json'
echo "收到数据: ${data}"
```

**关键技巧：** 用 `.ready` 等标记文件避免上游读到不完整的写入。

### 方案三：REST API 回调 —— 解耦最好

下游通过 `httpRequest` 主动回调上游暴露的接口：

```groovy
// 下游流水线
httpRequest url: "${PARENT_CALLBACK_URL}/status",
    httpMode: 'POST',
    contentType: 'APPLICATION_JSON',
    requestBody: groovy.json.JsonOutput.toJson([
        build: env.JOB_NAME,
        status: 'IN_PROGRESS',
        url: env.SERVICE_URL
    ])
```

这种方式高度解耦，下游可以在任何关键阶段主动通知上游。

### 方案四：消息队列（MQ）—— 适合大规模系统

通过 RabbitMQ 等消息队列实现解耦：

```groovy
// 下游流水线
mqSend connection: 'my-rabbitmq',
    exchange: 'jenkins.exchange',
    routingKey: 'build.status',
    message: """{
        "build": "${env.JOB_NAME}",
        "status": "IN_PROGRESS",
        "data": "some-intermediate-data"
    }"""
```

适合构建大规模、分布式的 CI/CD 系统。

### 方案五：读取 `currentBuild.description`

下游将信息写入构建描述：

```groovy
// 下游流水线
currentBuild.description = groovy.json.JsonOutput.toJson([
    logDir: env.DeployName,
    url: env.SERVICE_URL
])
```

上游轮询读取：

```groovy
def getBuildDescription(String jobName, int buildNumber) {
    def job = Jenkins.instance.getItemByFullName(jobName)
    def build = job.getBuildByNumber(buildNumber)
    return build?.getDescription()
}
```

**注意：** 这种方法适合临时调试或简单场景。描述字段设计用途是给人看的，不是给程序通信的结构化数据。生产环境更推荐共享变量或共享存储。

## 实战：改造异步调用函数以支持信息追踪

假设你有一个封装好的 `asyncDownstream` 函数用于异步触发下游，可以这样改造它，使其返回下游的构建号：

```groovy
def asyncDownstreamWithTracking(String jobName, List params) {
    def encodedBranch = java.net.URLEncoder.encode(env.CURRENT_PIPELINE_BRANCH, 'UTF-8')
    def fullJobName = "${jobName}/${encodedBranch}"

    // 通过 Jenkins API 获取队列中的构建
    def queueItem = Jenkins.instance.queue.schedule(
        Jenkins.instance.getItemByFullName(fullJobName),
        0,
        params
    )

    if (queueItem) {
        // 等待构建真正进入队列并获取 build number
        sleep 2
        def job = Jenkins.instance.getItemByFullName(fullJobName)
        def lastBuild = job.getLastBuild()
        return [
            jobName: fullJobName,
            buildNumber: lastBuild.number
        ]
    }
    error "无法调度 ${fullJobName}"
}
```

然后在父流水线中使用：

```groovy
def downstream = asyncDownstreamWithTracking('Helm-Start-Service-MB', params)

// 父流水线继续做其他事...
echo "下游已触发: ${downstream.jobName} #${downstream.buildNumber}"

// 需要时轮询读取下游信息
def info = waitForDownstreamInfo(downstream.jobName, downstream.buildNumber)
echo "下游返回: ${info}"
```

## 决策路径：如何选择？

| 场景 | 推荐方案 |
|------|----------|
| 简单可靠，想尽快拿到结果 | 同步触发 + `buildVariables` |
| 需传递大文件，有共享存储可用 | 共享存储 + 标记文件 |
| 解耦，下游"知道"上游是谁 | REST API 回调 |
| 大规模、高并发、强解耦 | 消息队列（MQ） |
| 只是触发一下，不需要结果 | `wait: false` |

## 最佳实践总结

1. **异步不等于无序** —— 跨流水线通信仍需业务协议保证逻辑正确性，建议为所有消息设定全局唯一的 `traceId` 方便追踪
2. **轮询要有优雅退出** —— 设置超时和清理逻辑，避免死循环和垃圾文件堆积
3. **数据格式用 JSON/YAML** —— 提高可读性和可扩展性
4. **敏感信息要脱敏** —— 使用 `maskPasswords` 等步骤隐藏敏感数据
5. **规避循环依赖** —— 避免上游调下游、下游又回调上游的死循环
6. **Executor 资源有限** —— 异步触发的子流水线同样占用 executor，数量不足时会进入排队

## 结语

Jenkins 流水线的异步调用和跨流水线通信是一个看似简单但细节丰富的话题。掌握 `wait: false`、`parallel`、REST API 这些基础方法，再根据实际需求选择合适的信息回传方案，你就能构建出灵活高效的 CI/CD 流水线体系。

如果你的场景是"触发下游后做其他事，但最终必须等下游完成"，其实可以考虑另一种更简洁的模式：用同步触发一个"快速启动"的 job，然后父流水线自己做健康检查轮询服务端点。这种方式比复杂的异步通信要简单可靠得多。
