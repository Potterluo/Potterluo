#!/usr/bin/env node

import { readFileSync, writeFileSync } from "node:fs";

const FEED_URL = "https://keriko-blog.pages.dev/rss.xml";
const README = "README.md";
const MAX_POSTS = 6;
const START = "<!-- BLOG-POST-LIST:START -->";
const END = "<!-- BLOG-POST-LIST:END -->";

const decode = (value) =>
  value
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .trim();

const xml = process.env.RSS_FILE
  ? readFileSync(process.env.RSS_FILE, "utf8")
  : await fetch(FEED_URL, {
      headers: { "user-agent": "Potterluo-profile-readme" },
    }).then((response) => {
      if (!response.ok) {
        throw new Error(`Failed to fetch RSS feed: ${response.status}`);
      }
      return response.text();
    });

const posts = [...xml.matchAll(/<item>([\s\S]*?)<\/item>/g)]
  .map(([, item]) => {
    const title = decode(item.match(/<title>([\s\S]*?)<\/title>/)?.[1] ?? "");
    const link = decode(item.match(/<link>([\s\S]*?)<\/link>/)?.[1] ?? "");
    const published = decode(item.match(/<pubDate>([\s\S]*?)<\/pubDate>/)?.[1] ?? "");
    return { title, link, time: Date.parse(published) || 0 };
  })
  .filter((post) => post.title && post.link);

// Newest first; for posts published on the same day, the larger slug is newer.
posts.sort((a, b) => b.time - a.time || b.link.localeCompare(a.link));

const formatDate = (time) => new Date(time).toISOString().slice(0, 10);
const escapeTitle = (title) => title.replace(/([\\[\]])/g, "\\$1");

const lines = posts
  .slice(0, MAX_POSTS)
  .map((post) => `- [${escapeTitle(post.title)}](${post.link}) · ${formatDate(post.time)}`);

const readme = readFileSync(README, "utf8");
const startIndex = readme.indexOf(START);
const endIndex = readme.indexOf(END);

if (startIndex === -1 || endIndex === -1 || endIndex < startIndex) {
  throw new Error("Blog post markers were not found in README.md");
}

const nextReadme =
  readme.slice(0, startIndex) + `${START}\n${lines.join("\n")}\n` + readme.slice(endIndex);

if (nextReadme === readme) {
  console.log("README.md is already up to date.");
  process.exit(0);
}

writeFileSync(README, nextReadme);
console.log(`Updated ${lines.length} posts:`);
console.log(lines.join("\n"));
