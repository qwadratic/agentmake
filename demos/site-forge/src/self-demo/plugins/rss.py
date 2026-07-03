"""RSS plugin for site-forge. stdlib only.

on_site(site, out_dir): writes RSS 2.0 feed.xml at out_dir root.
Channel title/link/description come from site.json config keys of the same
names. One <item> per page: title, link (channel link + name.html),
description = text of first <p> in page html. Deterministic: no pubDate,
never wall clock.
"""
import os
import xml.etree.ElementTree as ET
from html.parser import HTMLParser


class _FirstPara(HTMLParser):
    def __init__(self):
        super().__init__()
        self.depth = 0
        self.done = False
        self.text = []

    def handle_starttag(self, tag, attrs):
        if tag == "p" and not self.done:
            self.depth += 1

    def handle_endtag(self, tag):
        if tag == "p" and self.depth:
            self.depth -= 1
            if self.depth == 0:
                self.done = True

    def handle_data(self, data):
        if self.depth and not self.done:
            self.text.append(data)


def _first_paragraph(html):
    p = _FirstPara()
    p.feed(html or "")
    return "".join(p.text).strip()


def on_site(site, out_dir):
    config = site.get("config", {})
    base = config.get("link", "")

    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = config.get("title", "")
    ET.SubElement(channel, "link").text = base
    ET.SubElement(channel, "description").text = config.get("description", "")

    for page in site.get("pages", []):
        item = ET.SubElement(channel, "item")
        ET.SubElement(item, "title").text = page.get("title", "")
        link = base.rstrip("/") + "/" + page.get("name", "") + ".html"
        ET.SubElement(item, "link").text = link
        desc = _first_paragraph(page.get("html", "")) or page.get("title", "")
        ET.SubElement(item, "description").text = desc

    data = ET.tostring(rss, encoding="unicode")
    with open(os.path.join(out_dir, "feed.xml"), "w", encoding="utf-8", newline="\n") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n' + data + "\n")
