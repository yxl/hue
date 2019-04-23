// Licensed to Cloudera, Inc. under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  Cloudera, Inc. licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const fs = require('fs');
const mkdirp = require('mkdirp');
const path = require('path');

const EPub = require('epub');

const Topic = require('./Topic');
const libxml = require('libxmljs');

const pathToEpub = '/Users/jahlen/Downloads/LanguageManual-v44-20190422_1813.epub';
const outputPath = '/Users/jahlen/dev/hue/desktop/core/src/desktop/static/desktop/docs/hive/';
const mako = '/Users/jahlen/dev/hue/desktop/core/src/desktop/templates/sql_doc_index.mako';

const jsonHandler = require('./jsonHandler');

const epub = new EPub(pathToEpub);

const convertToPre = (element, fragments) => {
  // console.log(element.name());
  switch (element.name()) {
    case 'div':
      element.childNodes().forEach(node => {
        convertToPre(node, fragments);
      });
      break;
    case 'text':
      if (fragments.length === 1) {
        fragments.push(element.text().replace(/^\n/, ''));
      } else {
        fragments.push(element.text());
      }
      break;
    case 'code':
      if (element.attr('class') && element.attr('class').value().indexOf('value') !== -1) {
        fragments.push('<span class="hue-doc-varname">');
        element.childNodes().forEach(node => {
          convertToPre(node, fragments);
        });
        fragments.push('</span>');
        break;
      }
    default:
      element.childNodes().forEach(node => {
        convertToPre(node, fragments);
      });
  }
};

const adaptElement = (element) => {
  if (element.attr('class') && element.attr('class').value().indexOf('syntaxhighlighter') !== -1) {
    let fragments = ['<div class="hue-doc-codeblock">'];
    element.childNodes().forEach(childNode => {
      convertToPre(childNode, fragments);
    });
    fragments.push('</div>');
    let replacement = fragments.join('');
    if (replacement.indexOf('WITH CommonTableExpression') !== -1) {
      console.log(replacement);
    }
    // console.log(replacement);
    // console.log();
    element.replace(libxml.parseHtmlFragment(replacement).root());
  } else if (element.attr('class')) {
    element.attr('class').remove();
  }
  // if (element.attr('style')) {
  //   element.attr('style').remove();
  // }
  element.childNodes().forEach(adaptElement);
};

epub.on("end", function(){
  let savePromises = [];
  // console.log(epub.flow);

  let rootTopics = [];
  let topicStack = [];

  let lastTopicPerLevel = {};

  let promises = [];

  epub.flow.forEach(chapter => {
    promises.push(new Promise((resolve, reject) => {
      let topic = new Topic('/', chapter.id);
      topic.fragment = {
        title : {
          text: () => chapter.title.replace(/LanguageManual\s(.+)/, '$1')
        }
      };

      epub.getChapter(chapter.id, (error, text) => {
        try {
          let contents = libxml.parseHtmlFragment('<div>' + text + '</div>');
          topic.domXml = contents.root();
          adaptElement(topic.domXml);
          resolve();
        } catch (error) {
          reject();
        }
      });

      if (lastTopicPerLevel[chapter.level - 1]) {
        lastTopicPerLevel[chapter.level - 1].children.push(topic);
      }

      if (chapter.level === 0) {
        rootTopics.push(topic);
      }

      lastTopicPerLevel[chapter.level] = topic;
    }));
  });

  Promise.all(promises).then(() => {
    jsonHandler.saveTopics(rootTopics, outputPath, mako, false).then(() => {
      console.log('Done.');
    }).catch(() => {
      console.log('Fail.');
    });
  });
});

epub.parse();