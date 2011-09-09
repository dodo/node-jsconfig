
# jsconfig

loading configs from javascript files with default configs and cli support

## installation

    npm install jsconfig

## usage

```javascript
var config = require('jsconfig');
config.load('./config.js', function () {
    console.log(config);
});

// in another file
config = require('jsconfig'); // this is filled after config.load call

```


a normal config file structures looks like this:

```javascript
module.exports = {};
```

### config.load


```javascript
config.load('./db-config.js', './server-config.js'/*, […]*/);
console.log(config);
// or
config.load('./db-config.js', './server-config.js'/*, […]*/, function () {
    console.log(config);
});
```

load all config files and fills config with all settings.

 __required__

### config.defaults

```javascript
config.defaults('./db-config.default.js', './server-config.default.js'/*, […]*/);
```

load some default config files.

### config.set

```javascript
config.set('ignore unknown', true); // default is false
```

ignore all nonexisting config files and options.

does not apply on default config files.

```javascript
config.set('env', {USER: 'user.name'}); // similar to config.user.name = process.env.USER
```

define all environment variables, that should be included into config.

this overwrites config file values (default config files too).

### config.cli

```javascript
config.cli({
    user:  ['user.name', ['u', "user name", 'string']],
    debug: [false, "debug mode", 'bool'],
}); // results only in config.user.name = opts.user (after config.load call)
```

this sets up the command line interface. its basicly [node-cli](https://github.com/chriso/cli) with on little change: if cli result should be saved in config,
the cli-array should be packed into a second (outer) array as second element (the first is the position in the config object).




