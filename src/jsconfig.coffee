fs = require 'fs'
cli = require 'cli'
async = require 'async'
{ deep_merge, deep_set, deep_get, inplace_merge, load_files } = require './util'
{ isArray } = Array


defaults = {}
map = env:{}, opts:{}, args:[]
options =
    'cli': no
    'cli parse': no
    'ignore unknown':no


module.exports = config =
    defaults: (files...) ->
        defaults = deep_merge defaults, load_files files...
        return this

    set: (key, value) ->
        if map[key]?
            map[key] = value
        else
            options[key] = value
        return this

    cli: (opts) ->
        if typeof opts is 'function'
            options['cli'] = opts
        else
            options['cli'] = yes if options['cli'] is no
            if isArray(opts)
                options['cli parse'] = [] if options['cli parse'] is no
                options['cli parse'] = options['cli parse'].concat opts
            else
                options['cli parse'] = {} if options['cli parse'] is no
                inplace_merge options['cli parse'], opts
        return this

    load: (files..., callback) ->
        # when no callback given then it's a file
        unless typeof callback is 'function'
            files.push callback
            callback = undefined

        # when cli is enabled we totally need a callback
        if options['cli'] and not callback?
            throw new Error 'if you want to use cli you have to provide a callback.'

        # load environment ontop of defaults
        for key, target of map.env
            continue unless process.env[key]?
            if isArray(target)
                # do something special with env value, e.g. parsing it
                deep_set defaults, target[0], target[1](process.env[key])
            else
                deep_set defaults, target, process.env[key]
        # copy defaults
        conf = deep_merge {}, defaults

        # callback for when cli is ready or sync call
        finish = (args, opts) ->
            # environment has higher priority .. so we put it on top again
            for key, target of map.env
                continue unless process.env[key]?
                if isArray(target)
                    # do something special with env value, e.g. parsing it
                    deep_set conf, target[0], target[1](process.env[key])
                else
                    deep_set conf, target, process.env[key]

            if opts?
                # merge options into config
                for key, target of map.opts
                    continue unless opts[key]
                    # only set when differs from defaults
                    continue if opts[key] is deep_get(defaults, target)
                    deep_set conf, target, opts[key]
            # remove loader code
            for key in ['defaults', 'set', 'cli', 'load']
                delete config[key]
            # delete old defaults
            defaults = {}
            # insert all loaded values
            inplace_merge config, conf
            # when sync call, callback is undefined
            callback?.apply this, arguments

        load_configs = (args...) ->
            # put configs ontop of defaults
            if options['ignore unknown']
                if callback?
                    # async call
                    iter = (file, callback) ->
                        fs.stat file, (err) ->
                            return callback(err) if err
                            callback(null, file)
                    async.map files, iter, (err, existing_files) =>
                        conf = deep_merge conf, load_files existing_files...
                        finish.apply this, args
                else
                    # sync call
                    existing_files = []
                    for file in files
                        try
                            fs.statSync(file)
                            existing_files.push file
                        catch e
                            # do nothing
                    conf = deep_merge conf, load_files existing_files...
                    finish.apply this, args
            else
                conf = deep_merge conf, load_files files...
                finish.apply this, args


        # set a default cli invoke when enabled andnot function is given
        unless options['cli'] is no or typeof options['cli'] is 'function'
            options['cli'] = (callback) -> cli.main callback

        if options['cli']
            if options['ignore unknown']
                # ignore all unknown arguments and options
                # the user will try to use on cli
                cli.fatal = (msg, type) ->
                    type = 'error' if type is 'fatal'
                    cli.status(msg, type)

            if options['cli parse']?
                for key, value of options['cli parse']
                    if isArray(value) and isArray(value[1])
                        # explicit mapping
                        map.opts[key] = value[0]
                        options['cli parse'][key] = value = value[1]
                    if map.opts[key]? and value.length is 3
                        # if no default value for cli is given,
                        # we predict it from default config
                        value.push deep_get conf, map.opts[key]
                cli.parse options['cli parse']
            # async call
            options['cli'] load_configs
            return
        else
            # sync call
            return load_configs()
