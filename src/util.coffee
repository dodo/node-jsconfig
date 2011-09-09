{ isArray } = Array


deep_merge = (objs...) ->
    objs = objs[0] if isArray(objs[0])
    res = {}
    for obj in objs
        for k, v of obj
            if typeof(v) is 'object' and not isArray(v)
                res[k] = deep_merge(res[k] or {}, v)
            else
                res[k] = v
    res


deep_set = (obj, target, value) ->
    pointer = obj
    target = target.split('.')
    key = target.pop()
    for part in target
        pointer[part] = {} unless pointer[part]?
        pointer = pointer[part]
    pointer[key] = value
    obj


deep_get = (obj, target) ->
    target = target.split('.')
    key = target.pop()
    for part in target
        obj = obj[part]
        return unless obj?
    obj[key]



inplace_merge = (target, obj) ->
    for k, v of obj
        target[k] = v
    target


load_files = (files...) ->
    conf = {}
    for file in files
        conf = deep_merge conf, require(file)
    conf


module.exports = { deep_merge, deep_set, deep_get, inplace_merge, load_files }
