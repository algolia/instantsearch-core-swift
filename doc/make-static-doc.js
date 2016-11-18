#!/usr/bin/env node

var Metalsmith  = require('metalsmith');
var sass        = require('metalsmith-sass');
var markdown    = require('metalsmith-markdown');
var layouts     = require('metalsmith-layouts');
var rootPath    = require('metalsmith-rootpath');
var serve       = require('metalsmith-serve');
var watch       = require('metalsmith-watch');
var metallic    = require('metalsmith-metallic');
var sitemap     = require('metalsmith-mapsite');
var asset       = require('metalsmith-static');
// var helpers     = require('metalsmith-register-helpers');
var headingsid  = require('metalsmith-headings-identifier');
// var file        = require('./plugins/file/index.js');
var imagemin    = require('metalsmith-imagemin');
var child_process = require("child_process");


// var sassPaths = [
//     'node_modules/foundation-sites/scss'
// ];

const BASE_URL = "https://community.algolia.com/algoliasearch-helper-swift";

const VERSION = child_process.execSync(
    "grep -E \"version\\s*=\\s*'[0-9.]+'\" " + __dirname + "/../AlgoliaSearch-Helper-Swift.podspec",
    {
        "encoding": "UTF-8"
    }
).split("'")[1];

var siteBuild = Metalsmith(__dirname)
    // Allow for relative url generation.
    .metadata({
        title: "AlgoliaSearch Helper for Swift",
        url: BASE_URL,
        github_url: "https://github.com/algolia/algoliasearch-helper-swift",
        version: VERSION,
        time: new Date().getTime()
    })
    .source("src")
    .destination("build")
    // Compile Sass stylesheets
    .use(sass({
        // includePaths: "css",
        outputDir: "css/",
        outputStyle: "expanded",
    }))
    // // Copy vendor assets to the build.
    // .use(asset({
    //     src: './node_modules/jquery/dist',
    //     dest: './deps/jquery'
    // }))
    // .use(asset({
    //     src: './node_modules/foundation-sites/dist',
    //     dest: './deps/foundation-sites'
    // }))
    // Syntax highlight code fragments.
    .use(metallic())
    // Parse Markdown.
    .use(markdown())
    // // Register custom handlebars helpers.
    // .use(helpers({
    //     directory: 'helpers'
    // }))
    // TODO: What is it?
    .use(headingsid())
    // Inject rootPath in every file metadata to be able to make all urls relative.
    // Allows to deploy the website in a directory.
    .use(rootPath())
    .use(layouts({
        engine: "mustache",
        partials: "partials"
    }))
    // Generate a `sitemap.xml`.
    .use(sitemap(BASE_URL))
    ;

// if (process.env.NODE_ENV !== 'production') {
//     siteBuild
//     // Serve on localhost:8080.
//     .use(serve())
//     // Watch for changes.
//     .use(
//         watch({
//             paths: {
//                 '${source}/**/*.md': true,
//                 '${source}/img/**/*.*': true,
//                 '${source}/sass/**/*.scss': 'sass/app.scss',
//                 'layouts/**/*.html': '**/*.md',
//                 'partials/**/*.html': '**/*.md'
//             },
//             livereload: true,
//         })
//     );
// }

// Display errors.
siteBuild.build(function(err, files) {
    if (err) {
        throw err;
    }
});
