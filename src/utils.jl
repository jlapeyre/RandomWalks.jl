export logrange

# FIXME: how about an easy, *performant*, lazy version ?
logrange(itr) = collect(exp10(x) for x in itr)
