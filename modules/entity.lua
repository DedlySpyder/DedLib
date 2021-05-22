local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib", prefix = "Entity"}
local Area = require("__DedLib__/modules/area")
local Position = require("__DedLib__/modules/position")

local Entity = {}

function Entity.is_valid(entity) --TODO - performance? - cacheable (unit num + tick)?
    return entity and entity.valid
end

function Entity.area_of(entity) -- TODO - moved from Area.area_of_entity
    Logger.trace("Finding area of entity")
    if Entity.is_valid(entity) then
        return Entity.area_of_bounding_box(entity.bounding_box)
    else
        Logger.error("Entity is nil or invalid")
    end
end

function Entity.area_of_bounding_box(bb)
    Logger.trace("Finding area of bounding box: %s", bb)
    bb = Area.standardize_bounding_box(bb)
    if bb then
        local area = (math.ceil(bb.right_bottom.x) - math.floor(bb.left_top.x)) * (math.ceil(bb.right_bottom.y) - math.floor(bb.left_top.y))
        Logger.trace("Area of bounding box is <%s> tiles", area)
        return area
    else
        Logger.error("Failed to standardize bounding box for valid entity")
    end
end

function Entity.area_of_bounding_box_lt_rb(left_top, right_bottom)
    return Entity.area_of_bounding_box({
        left_top = left_top,
        right_bottom = right_bottom
    })
end

-- See `docs/entity_area_by_chunks.png` (on GitHub, not packaged in the mod) for examples on how this math makes sense
function Entity.area_of_by_chunks(entity) -- TODO tests - big boi
    Logger.trace("Finding area of entity by chunks")
    if Entity.is_valid(entity) then
        local chunks, vertices = Entity.chunks_of(entity)
        if #chunks == 0 then
            return {}

        elseif #chunks == 1 then
            -- Use normal area_of if there is only 1 chunk anyways
            local areas = {{chunk = chunks[1], area = Entity.area_of(entity)}}
            Logger.trace_block("Calculated areas of entity %s within 1 chunk: %s", entity.name, areas)
            return areas

        elseif #chunks == 2 then
            local leftTopChunk, rightBottomChunk = chunks[1], chunks[2]
            local areas = {}
            if leftTopChunk.x < rightBottomChunk.x then
                -- Vertical split
                areas[1] {
                    chunk = leftTopChunk,
                    area = Entity.area_of_bounding_box_lt_rb(vertices.left_top, {
                        x = Area.get_chunk_area_from_chunk_position(leftTopChunk).right_bottom.x,
                        y = vertices.right_bottom.y
                    })
                }
                areas[2] {
                    chunk = rightBottomChunk,
                    area = Entity.area_of_bounding_box_lt_rb({
                        x = Area.get_chunk_area_from_chunk_position(rightBottomChunk).top_left.x,
                        y = vertices.top_left.y
                    }, vertices.right_bottom)
                }
            elseif leftTopChunk.y < rightBottomChunk.y then
                -- Horizontal split
                areas[1] {
                    chunk = leftTopChunk,
                    area = Entity.area_of_bounding_box_lt_rb(vertices.left_top, {
                        x = vertices.right_bottom.x,
                        y = Area.get_chunk_area_from_chunk_position(leftTopChunk).right_bottom.y
                    })
                }
                areas[2] {
                    chunk = rightBottomChunk,
                    area = Entity.area_of_bounding_box_lt_rb({
                        x = vertices.top_left.x,
                        y = Area.get_chunk_area_from_chunk_position(rightBottomChunk).top_left.y
                    }, vertices.right_bottom)
                }
            else
                -- WTF??
                Logger.fatal_block("Chunks for area_of_by_chunks calculation are unexpected: leftTopChunk <%s> rightBottomChunk <%s>",
                        leftTopChunk,
                        rightBottomChunk
                )
                error("Fatal assertion error in DedLib for area of entity by chunk calculation. Please report " ..
                        "on the mod portal with factorio-current.log file")
            end

            Logger.trace_block("Calculated areas of entity %s within 2 chunks: %s", entity.name, areas)
            return areas

        else -- 4 Chunks
            local leftTopChunk = chunks[1]
            local centerPoint = Area.get_chunk_area_from_chunk_position(leftTopChunk).right_bottom
            local areas = {
                -- top_left
                {
                    chunk = leftTopChunk,
                    area = Entity.area_of_bounding_box_lt_rb(vertices.left_top, centerPoint)
                },
                -- right_bottom
                {
                    chunk = chunks[2],
                    area = Entity.area_of_bounding_box_lt_rb(centerPoint, vertices.right_bottom)
                },
                -- left_bottom
                {
                    chunk = chunks[3],
                    area = Entity.area_of_bounding_box_lt_rb({
                        x = vertices.left_bottom.x,
                        y = centerPoint.y
                    }, {
                        x = centerPoint.x,
                        y = vertices.left_bottom.y
                    })
                },
                -- right_top
                {
                    chunk = chunks[4],
                    area = Entity.area_of_bounding_box_lt_rb({
                        x = centerPoint.x,
                        y = vertices.right_top.y
                    }, {
                        x = vertices.right_top.x,
                        y = centerPoint.y
                    })
                }
            }
            Logger.trace_block("Calculated areas of entity %s within 4 chunks: %s", entity.name, areas)
            return areas
        end
    end
end

-- Returns 1, 2, or 4 chunks in the following order of the entities bounding box:
-- - left_top position's chunk
-- -- right_bottom position's chunk
-- --- left_bottom position's chunk
-- --- right_top position's chunk
-- 2nd returned value is the vertices of the entity
function Entity.chunks_of(entity) -- TODO tests
    Logger.trace("Finding chunks of entity")
    if Entity.is_valid(entity) then
        local bb = entity.bounding_box
        if bb then
            local leftTop = bb.left_top
            local rightBottom = bb.right_bottom
            local leftTopChunk = Area.get_chunk_position_from_position(leftTop)
            local rightBottomChunk = Area.get_chunk_position_from_position(rightBottom)

            local chunks = {leftTopChunk}
            -- If the left top and right bottom are in the same chunk, then the whole entity is in the same chunk
            if Position.compare(leftTopChunk, rightBottomChunk) then
                Logger.trace("Entity %s is only in one chunk: %s", entity.name, leftTopChunk)
                return chunks
            else
                -- If the 2 opposing corners are in different chunks then the non-checked corners could also be in different chunks
                -- This is assuming entities are smaller than 32 tiles, so massive entities will break this
                chunks[2] = rightBottomChunk

                local vertices = Area.get_bounding_box_vertices(bb)
                local leftBottomChunk = Area.get_chunk_position_from_position(vertices.left_bottom)
                local rightTopChunk = Area.get_chunk_position_from_position(vertices.right_top)

                -- We know the entity crosses at least one chunk boundary, so a corner can _only_ be in the same chunk
                -- as an adjacent corner. So, the new corners only need compared to the original 2 corners for new chunks to be found
                -- Additionally, we can never have a entity in only 3 chunks as a basic rule
                if not (Position.compare(leftTopChunk, leftBottomChunk) or Position.compare(rightBottomChunk, leftBottomChunk)) then
                    table.insert(chunks, leftBottomChunk)
                    table.insert(chunks, rightTopChunk)
                end
                Logger.trace("Entity %s is in multiple chunks: %s", entity.name, chunks)
                return chunks, vertices
            end
        end
    else
        Logger.error("Entity is nil, invalid, or missing bounding_box")
        return {}, {}
    end
end

return Entity