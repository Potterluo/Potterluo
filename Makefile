.PHONY: help serve build clean deploy

help: ## 显示帮助信息
	@echo "Keriko 播客系统 - 可用命令："
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

serve: ## 启动开发服务器 (http://localhost:1313)
	@echo "🚀 启动开发服务器..."
	@hugo server -D --buildDrafts

build: ## 构建生产版本
	@echo "🔨 构建网站..."
	@hugo --minify
	@echo "✅ 构建完成！输出目录: public/"

clean: ## 清理构建文件
	@echo "🧹 清理构建文件..."
	@rm -rf public/
	@rm -rf resources/
	@echo "✅ 清理完成"

new: ## 创建新节目 (使用: make new TITLE=新节目标题)
	@if [ -z "$(TITLE)" ]; then \
		read -p "请输入节目标题: " title; \
		hugo new podcast/$$title.md; \
	else \
		hugo new podcast/$(TITLE).md; \
	fi

drafts: ## 查看所有草稿
	@find content/podcast -name "*.md" -exec grep -l "draft: true" {} \; | while read file; do \
		echo "📝 $$file"; \
	done

deploy-gitee: build ## 部署到 Gitee Pages
	@echo "📤 部署到 Gitee Pages..."
	@git add .
	@git commit -m "Deploy: $$(date '+%Y-%m-%d %H:%M:%S')"
	@git push origin master
	@echo "✅ 部署完成！请在 Gitee 上手动更新 Pages"

deploy-github: build ## 部署到 GitHub Pages
	@echo "📤 部署到 GitHub Pages..."
	@git add .
	@git commit -m "Deploy: $$(date '+%Y-%m-%d %H:%M:%S')"
	@git push github master
	@echo "✅ 部署完成！"

update-theme: ## 更新 Qubt 主题到最新版本
	@echo "🔄 更新主题..."
	@hugo mod get -u github.com/chrede88/qubt
	@echo "✅ 主题更新完成！"

check: ## 检查配置和链接
	@echo "🔍 检查配置..."
	@hugo check
	@echo "✅ 配置检查完成"

test: build ## 测试构建
	@echo "🧪 测试构建..."
	@hugo --minify --buildDrafts
	@echo "✅ 测试构建成功！"

install-deps: ## 安装依赖
	@echo "📦 安装依赖..."
	@hugo mod get github.com/chrede88/qubt@latest
	@echo "✅ 依赖安装完成！"

stats: ## 显示网站统计信息
	@echo "📊 网站统计："
	@echo "节目总数: $$(find content/podcast -name "*.md" | wc -l)"
	@echo "草稿数量: $$(grep -r "draft: true" content/podcast | wc -l)"
	@echo "音频文件: $$(find static/audio -name "*.mp3" 2>/dev/null | wc -l)"
	@echo "总大小: $$(du -sh static/ 2>/dev/null | cut -f1)"

.DEFAULT_GOAL := help
