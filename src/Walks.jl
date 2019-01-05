module Walks

using ..WalksBase
using ..Actors

function walk!(walk::AbstractWalk, actor::AbstractActor)
    init!(walk)
    Actors.init!(actor)
    while step!(walk) && Actors.act!(actor, walk)
    end
    return walk
end

end
