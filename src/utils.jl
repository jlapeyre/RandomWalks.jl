export logrange

# FIXME: how about an easy, *performant*, lazy version ?
function logrange(itr)
    return collect(exp10(x) for x in itr)
end
