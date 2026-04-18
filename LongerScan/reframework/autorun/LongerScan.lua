local modname = "LongerScan"
local author = "xyzkljl1"
local sourceweb = "Nexus"
local version = "v1.0"
local configfile = modname..".json"
local _config={
    {name="time", label = "display time(seconds)",type="int",default=1200,min=1,max=36000}, -- seconds, 10 by game default
    --{name="range",type="int",default=60,min=1,max=250},
    --{name="rate",type="int",default=60,min=1,max=250},
}
local config = {}
print("["..modname..version.."]["..author.."]["..sourceweb.."] Start")

--settings
local function Log(...)
    print(...)
    for k,v in ipairs{...} do
        log.info("["..modname.."]"..tostring(v))
    end
end

local scanManager=sdk.get_managed_singleton("app.ScanManager")
sdk.hook(sdk.find_type_definition("app.ScanManager"):get_method("requestScan"), function ()
    Log("onScan")
    scanManager:get_userdata().Basic.ScanDisplayTime = config.time
end
, nil)


-- utils
local function recurse_def_settings(tbl, new_tbl)
	for key, value in pairs(new_tbl) do
		if type(tbl[key]) == type(value) then
		    if type(value) == "table" then
			    tbl[key] = recurse_def_settings(tbl[key], value)
            else
    		    tbl[key] = value
            end
        elseif type(value)~=nil and type(tbl[key])~=nil then
            -- for boolList default value
            tbl[key]=value
		end
	end
	return tbl
end

local function InitFromFile(_config,configfile)
    --merge config file to default config
    local config = {} 
    for key,para in ipairs(_config) do
        if para.name~=nil then
            config[para.name]=para.default
        end
    end
    config= recurse_def_settings(config, json.load_file(configfile) or {})
    return config
end

local function DrawIt(modname,configfile,_config,config,OnChange)
    configfile=configfile or (modname..".json")
    Log("CAll DrawIt")

    re.on_draw_ui(function()
        local changed=false--tmp
        local _changed=false--final

        local triggeredButtons={}
	    if imgui.tree_node(modname) then
		    --imgui.same_line()
		    --imgui.text("*Right click on most options to reset them")
		    imgui.begin_rect()
            for _,para in ipairs (_config) do
                local key = para.name
                local actionName = para.actionName or key
                local title_postfix=""
                local label=para.label or key

                if para.type=="int" then
        		    changed , config[key]= imgui.drag_int(label .. title_postfix, 
                                                            config[key] or para.default or para.min or 0,
                                                            para.step or 1 , para.min or 0, para.max or 100)
                    _changed=changed or _changed
                elseif para.type=="bool" then
                    --don't use "config[key] or default"
                    if config[key] ~=nil then
            		    changed , config[key]= imgui.checkbox(label .. title_postfix, config[key])
                    else
            		    changed , config[key]= imgui.checkbox(label .. title_postfix, para.default)
                    end
                    _changed=changed or _changed
                elseif para.type=="author" then
                    imgui.text_colored(para.name or "\tAuthor: xyzkljl1",para.color or 0xffffffff)
                end

            end
            --Add an empty line to prevent the last setting ui's last line is not shown properly
            imgui.text()
            imgui.end_rect()
		    imgui.tree_pop()
        end        

        --should call before on change?
        for key,func in pairs(triggeredButtons) do 
            func.func(func.para)
        end

        if _changed==true then
            json.dump_file(configfile, config)
            if OnChange~=nil then
                OnChange()
            end
        end
    end)
end

config = InitFromFile(_config, configfile)
DrawIt(modname, configfile, _config, config, nil)
