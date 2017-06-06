package.path = './lib/?.lua;' .. package.path
require "xml"
require "handler"
require "tableToXML"



json = require "json"

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end


local function contains(table, val)
   for i=1,#table do
      if table[i] == val then 
         return true
      end
   end
   return false
end


local function jsonLoop(jsonList,tagValue,NclBody,key) -- jsonFile.results[1].result.tag.classes,tagValue,xmlhandlerNCL.root.ncl.body,contador,key
   
if tagValue then
   for k, v in pairs(jsonList) do -- clearly only works for clarifai responses.
         -- dentro de cada segundo verifica se tem a tag que quero.
        for i,j in pairs(v) do
          if tostring(j) == tagValue then
          --  print(k.." - "..tostring(j))
            if jsonList[k-1] == nil or not contains(jsonList[k-1], tostring(j))  then
             -- print (k .. "- inicio de tag")
              inicio = k 
            end
            cont = k
          --  print (k)
          end
        end

          if jsonList[k+1] == nil or contains(jsonList[k],tagValue) and not contains(jsonList[k+1],tagValue) then
           -- print(k .. "- fim de tag")
            cont = nil
            final = k

            NclBody.media[key]["area"][contador] = {_attr={}}
            NclBody.media[key]["area"][contador]._attr["id"] = "A_" .. tagValue .. "_" .. tostring(acc)
            NclBody.media[key]["area"][contador]._attr["begin"] = tostring(inicio).. 's' -- inicio da tag
            NclBody.media[key]["area"][contador]._attr["end"] =  tostring(final)..'s' -- inicio da tag
            contador = contador + 1 

            fillLinks(NclBody.link,tagValue)

          acc = acc + 1
          end
        end -- end for kv

  else
    print("sem tags encontradas")
  end

end

function fillLinks(link,tagValue) -- NclBody.link,tagValue
  for kb, vb in pairs(link) do
    if link[kb]._attr.bindtag then
      bindComponents = split(link[kb]._attr.bindtag, ".") -- 1 = video, 2 = sea
      if bindComponents[2] == tagValue then
        -- copia o nó original e remove itens
        newTable = deepcopy(link[kb])
        table.removekey(newTable._attr,"bindtag")
        -- explode esse nó em outro
        newTable.bind[1]._attr.interface = "A" .. tagValue .. tostring(acc)
        table.insert(link,newTable)
      end
    end
  end
end

function getTags(table)
  local tags = {}
  if table.area then 
    for i=1, #table.area do
      if table.area[i]._attr["tag"] then
        tags[i] = table.area[i]._attr["tag"]
      end
    end
    return tags
  end
end


function getAllTags(jsonList)
  local items={}
   for k, v in pairs(jsonList) do -- clearly only works for clarifai responses.
        for i,j in pairs(v) do
          if not contains(items,tostring(j)) then
              table.insert(items, tostring(j))
          end
        end
    end
    return items
end


local function has_value (tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

filename_in = "antes-main.ncl"
f, e = io.open(filename_in, "r")
if f then
  xmltextNCL = f:read("*a")
  else
    error(e)
end

--Instantiate the object the states the XML file as a Lua table
xmlhandlerNCL = simpleTreeHandler()

--Instantiate the object that parses the XML to a Lua table
xmlparserNCL = xmlParser(xmlhandlerNCL)
xmlparserNCL:parse(xmltextNCL)

res = showTable(xmlhandlerNCL.root)
--print(res)

-- loop principal, para cada video no arquivo.
for key,value in pairs(xmlhandlerNCL.root.ncl.body.media) do
  apiTags = getTags(value)
  if apiTags then
  --print(showTable(apiTags))
    videoFile = value._attr.src
    xmlhandlerNCL.root.ncl.body.media[key]._attr.tag = nil 

    os.execute("./resize_curl.sh video.mp4")
    os.execute("sleep 1")



    jsonPath = io.open("temp_out.json","r")
    jsonFile = json.parse(jsonPath:read("*all"))
    xmlhandlerNCL.root.ncl.body.media[key]["area"] = {}
  
    cont = nil
    contador = 1
    if apiTags[1] == "*" then
      allTags = getAllTags(jsonFile.results[1].result.tag.classes)
      for tagIndex,tagValue in pairs(allTags) do
         acc = 1
        jsonLoop(jsonFile.results[1].result.tag.classes,tagValue,xmlhandlerNCL.root.ncl.body,key) 
      end
    else
      for tagIndex,tagValue in pairs(apiTags) do
        acc = 1
        jsonLoop(jsonFile.results[1].result.tag.classes,tagValue,xmlhandlerNCL.root.ncl.body,key) 
      end 
    end
  end 
end 

-- cleanup
for kb, vb in pairs(xmlhandlerNCL.root.ncl.body.link) do
	if xmlhandlerNCL.root.ncl.body.link[kb]._attr.bindtag then
		 xmlhandlerNCL.root.ncl.body.link[kb] = nil
	end
end

writeToXml(xmlhandlerNCL.root,"anotado.ncl")

