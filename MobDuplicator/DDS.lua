-- =========================================================================
-- 1. Discrete Distribution Sampler (DDS) Class
-- =========================================================================
local DDS = {}
DDS.__index = DDS

function DDS:new(dist)
  local self = setmetatable({}, DDS)
  local n = 0
  local sum_tickets = 0
  for _, entry in pairs(dist) do
    n = n + 1
    sum_tickets = sum_tickets + entry.tickets
  end
  self.n = n

  local small = {}
  local large = {}

  for _, entry in pairs(dist) do
    local p = (entry.tickets / sum_tickets) * n
    if p < 1 then
      table.insert(small, {entry.outcome, p})
    else
      table.insert(large, {entry.outcome, p})
    end
  end

  local table_data = {}

  while #small > 0 and #large > 0 do
    local less = table.remove(small)
    local more = table.remove(large)
    table.insert(table_data, {less[2], less[1], more[1]})
    local remain = (more[2] + less[2]) - 1

    if remain < 1 then
      table.insert(small, {more[1], remain})
    else
      table.insert(large, {more[1], remain})
    end
  end

  while #large > 0 do
    local i = table.remove(large)
    table.insert(table_data, {1, i[1], i[1]})
  end
  while #small > 0 do
    local i = table.remove(small)
    table.insert(table_data, {1, i[1], i[1]})
  end

  self.table = table_data
  return self
end

function DDS:sample(r1, r2)
  if self.n == 0 then
    return 0
  end 

  local b_index = math.floor(r1 * self.n) + 1
  local bucket = self.table[b_index]

  if r2 > bucket[1] then
    return bucket[3]
  else
    return bucket[2]
  end
end

function DDS:roll()
  local r1 = math.random()
  local r2 = math.random()

  return tonumber(self:sample(r1, r2))
end

return DDS
