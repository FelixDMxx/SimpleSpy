--[[
	The reason I don't use string interpolation is because it is very slow.
	I'm already making this rather slow due to me using indexing vs 100 different elseif statements for the serialize function
	
	@TODO
	Unsupported DataTypes:
		CatalogSearchParams
		OverlapParams
		RaycastParams
		RaycastResult -- Unsure if I can even really support this due to it being created by doing WorldRoot:Raycast()
		Secret -- not sure how to even make this
]]
local SerializeClass = {}

local IsStudio = game:GetService("RunService"):IsStudio()

local FindService = game.FindService
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer do
	if not LocalPlayer then
		Players:GetPropertyChangedSignal("LocalPlayer"):Once(function()
			Players = Players.LocalPlayer
		end)
	end
end

local IsSharedFrozen = SharedTable.isFrozen
local SharedSize = SharedTable.size

local fromstring = buffer.fromstring
local bufftostring = buffer.tostring
local readu8 = buffer.readu8

local isfrozen = table.isfrozen
local concat = table.concat
local info = debug.info

local inf = math.huge
local neginf = -inf

local __mode = {__mode = "k"}
local DataTypes

local Enums = {} do
	for i,v in Enum:GetEnums() do
		Enums[v] = "Enum."..tostring(v)
	end
end

local Keywords do
	Keywords = {
		["local"] = "\"local\"",
		["function"] = "\"function\"",
		["type"] = "\"type\"",
		["typeof"] = "\"typeof\"",
		["and"] = "\"and\"",
		["break"] = "\"break\"",
		["not"] = "\"not\"",
		["or"] = "\"or\"",
		["else"] = "\"else\"",
		["elseif"] = "\"elseif\"",
		["if"] = "\"if\"",
		["then"] = "\"then\"",
		["until"] = "\"until\"",
		["repeat"] = "\"repeat\"",
		["while"] = "\"while\"",
		["do"] = "\"do\"",
		["for"] = "\"for\"",
		["in"] = "\"in\"",
		["end"] = "\"end\"",
		["return"] = "\"return\"",
		["export"] = "\"export\"",
		["continue"] = "\"continue\"",
		["true"] = "\"true\"",
		["false"] = "\"false\"",
		["nil"] = "\"nil\""
	}
end

local Signals do
	Signals = {
		GraphicsQualityChangeRequest = "game.GraphicsQualityChangeRequest",
		AllowedGearTypeChanged = "game.AllowedGearTypeChanged",
		ScreenshotSavedToAlbum = "game.ScreenshotSavedToAlbum",
		UniverseMetadataLoaded = "game.UniverseMetadataLoaded",
		ScreenshotReady = "game.ScreenshotReady",
		ServiceRemoving = "game.ServiceRemoving",
		ServiceAdded = "game.ServiceAdded",
		ItemChanged = "game.ItemChanged",
		CloseLate = "game.CloseLate",
		Loaded = "game.Loaded",
		Close = "game.Close",

		RobloxGuiFocusedChanged = "game:GetService(\"RunService\").RobloxGuiFocusedChanged",
		PostSimulation = "game:GetService(\"RunService\").PostSimulation",
		RenderStepped = "game:GetService(\"RunService\").RenderStepped",
		PreSimulation = "game:GetService(\"RunService\").PreSimulation",
		PreAnimation = "game:GetService(\"RunService\").PreAnimation",
		PreRender = "game:GetService(\"RunService\").PreRender",
		Heartbeat = "game:GetService(\"RunService\").Heartbeat",
		Stepped = "game:GetService(\"RunService\").Stepped"
	}
end

local ServiceGeneration do
	ServiceGeneration = {
		Workspace = "workspace",
		Lighting = "game.lighting",
		GlobalSettings = "settings()",
		Stats = "stats()",
		UserSettings = "UserSettings()",
		PluginManagerInterface = "PluginManager()",
		DebuggerManager = "DebuggerManager()"
	}
end

local SpecialCases do
	SpecialCases = {
		[7] = "\\a",
		[8] = "\\b",
		[9] = "\\t",
		[10] = "\\n",
		[11] = "\\v",
		[12] = "\\f",
		[13] = "\\r"
	}
end

local ReadableCharacters do
	ReadableCharacters = {
		[32] = " ",
		[33] = "!",
		[34] = "\\\"",
		[35] = "#",
		[36] = "$",
		[37] = "%",
		[38] = "&",
		[39] = "'",
		[40] = "(",
		[41] = ")",
		[42] = "*",
		[43] = "+",
		[44] = ",",
		[45] = "-",
		[46] = ".",
		[47] = "/",
		[48] = "0",
		[49] = "1",
		[50] = "2",
		[51] = "3",
		[52] = "4",
		[53] = "5",
		[54] = "6",
		[55] = "7",
		[56] = "8",
		[57] = "9",
		[58] = ":",
		[59] = ";",
		[60] = "<",
		[61] = "=",
		[62] = ">",
		[63] = "?",
		[64] = "@",
		[65] = "A",
		[66] = "B",
		[67] = "C",
		[68] = "D",
		[69] = "E",
		[70] = "F",
		[71] = "G",
		[72] = "H",
		[73] = "I",
		[74] = "J",
		[75] = "K",
		[76] = "L",
		[77] = "M",
		[78] = "N",
		[79] = "O",
		[80] = "P",
		[81] = "Q",
		[82] = "R",
		[83] = "S",
		[84] = "T",
		[85] = "U",
		[86] = "V",
		[87] = "W",
		[88] = "X",
		[89] = "Y",
		[90] = "Z",
		[91] = "[",
		[92] = "\\\\",
		[93] = "]",
		[94] = "^",
		[95] = "_",
		[96] = "`",
		[97] = "a",
		[98] = "b",
		[99] = "c",
		[100] = "d",
		[101] = "e",
		[102] = "f",
		[103] = "g",
		[104] = "h",
		[105] = "i",
		[106] = "j",
		[107] = "k",
		[108] = "l",
		[109] = "m",
		[110] = "n",
		[111] = "o",
		[112] = "p",
		[113] = "q",
		[114] = "r",
		[115] = "s",
		[116] = "t",
		[117] = "u",
		[118] = "v",
		[119] = "w",
		[120] = "x",
		[121] = "y",
		[122] = "z",
		[123] = "{",
		[124] = "|",
		[125] = "}",
		[126] = "~"
	}
end

local Globals do
	Globals = {
		[assert] = "assert",
		[error] = "error",
		[getfenv] = "getfenv",
		[getmetatable] = "getmetatable",
		[ipairs] = "ipairs",
		[loadstring] = "loadstring",
		[newproxy] = "newproxy",
		[next] = "next",
		[pairs] = "pairs",
		[pcall] = "pcall",
		[print] = "print",
		[rawequal] = "rawequal",
		[rawget] = "rawget",
		[rawlen] = "rawlen",
		[rawset] = "rawset",
		[select] = "select",
		[setfenv] = "setfenv",
		[setmetatable] = "setmetatable",
		[tonumber] = "tonumber",
		[tostring] = "tostring",
		[unpack] = "unpack",
		[xpcall] = "xpcall",
		[collectgarbage] = "collectgarbage",
		[delay] = "delay",
		[gcinfo] = "gcinfo",
		[PluginManager] = "PluginManager",
		[require] = "require",
		[settings] = "settings",
		[spawn] = "spawn",
		[tick] = "tick",
		[time] = "time",
		[UserSettings] = "UserSettings",
		[wait] = "wait",
		[warn] = "warn",
		[Delay] = "Delay",
		[ElapsedTime] = "ElapsedTime",
		[elapsedTime] = "elapsedTime",
		[printidentity] = "printidentity",
		[Spawn] = "Spawn",
		[Stats] = "Stats",
		[stats] = "stats",
		[Version] = "Version",
		[version] = "version",
		[Wait] = "Wait",
	}

	local function Convert(GlobalPath : string, tbl)
		for i,v in next, tbl do -- I don't technically need to use next here but just in the off chance you add your own tables
			local Type = type(v)

			if Type == "function" then
				Globals[v] = GlobalPath.."."..i
			elseif Type == "table" then
				Convert(GlobalPath.."."..i, v)
			end
		end
	end

	for i,v in {bit32 = bit32, buffer = buffer, coroutine = coroutine, debug = debug,  math = math, os = os, string = string, table = table, utf8 = utf8, Content = Content, Axes = Axes, BrickColor = BrickColor, CatalogSearchParams = CatalogSearchParams, CFrame = CFrame, Color3 = Color3, ColorSequence = ColorSequence, ColorSequenceKeypoint = ColorSequenceKeypoint, DateTime = DateTime, DockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo, Faces = Faces, FloatCurveKey = FloatCurveKey, Font = Font, Instance = Instance, NumberRange = NumberRange, NumberSequence = NumberSequence, NumberSequenceKeypoint = NumberSequenceKeypoint, OverlapParams = OverlapParams, PathWaypoint = PathWaypoint, PhysicalProperties = PhysicalProperties, Random = Random, Ray = Ray, RaycastParams = RaycastParams, Rect = Rect, Region3 = Region3, Region3int16 = Region3int16, RotationCurveKey = RotationCurveKey, SharedTable = SharedTable, task = task, TweenInfo = TweenInfo, UDim = UDim, UDim2 = UDim2, Vector2 = Vector2, Vector2int16 = Vector2int16, Vector3 = Vector3, Vector3int16 = Vector3int16} do
		Convert(i, v)
	end
end

local function Serialize(DataStructure : any, format : boolean?, indents : string, CyclicList) : string
	local DataType = typeof(DataStructure)
	local DataHandler = DataTypes[DataType]

	return DataHandler and DataHandler(DataStructure, format, indents, CyclicList) or "nil --[[ Unsupported Data Type | "..DataType.." ]]"
end

local function GetCyclicTables(tbl)
	local TableCache = setmetatable({}, __mode)
	local Cyclics = setmetatable({}, __mode)

	local function Search(tbl)
		local Identifier = getmetatable(tbl) == nil and tostring(tbl):sub(10) or tbl
		local copy = TableCache[Identifier]

		if not copy then
			TableCache[Identifier] = true

			for i,v in next, tbl do
				if type(v) == 'table' then
					Search(v)
				end
			end

			TableCache[Identifier] = nil
		else
			Cyclics[tbl] = "*** cycle table reference detected ***"
		end
	end

	Search(tbl)
	return Cyclics, true
end

local function nanToString(int : number)
	return int == int and int or "0/0"
end

local function SerializeString(RawString : string)
	local Lastunicode = nil
	local RawStringBuffer = fromstring(RawString)
	local SerializedString = ""

	for i = 0, #RawString-1 do
		local Byte = readu8(RawStringBuffer, i)

		if (Byte >= 32 and Byte <= 126) then
			local IsNumber = (Byte >= 48 and Byte <= 57)

			SerializedString ..= Lastunicode and IsNumber and "\"..\""..(Byte-48) or not IsNumber and ReadableCharacters[Byte] or Byte-48
			Lastunicode = nil
		else
			local IsUnicode = Byte < 7 or Byte > 13

			SerializedString ..= IsUnicode and "\\"..Byte or SpecialCases[Byte]
			Lastunicode = IsUnicode
		end
	end

	return "\""..SerializedString.."\""
end

local function SerializeNumber(num : number)
	return num ~= inf and num ~= neginf and num == num and num or num == inf and "math.huge"  or num == neginf and "-math.huge" or "0/0"
end

local function SerializeInstance(obj : Instance)
	local ObjectParent = obj.Parent
	local ObjectClassName = obj.ClassName

	if ObjectParent then	
		local ObjectName = SerializeString(obj.Name)

		if ObjectClassName ~= "Model" and ObjectClassName ~= "Player" then
			local IsService, Output = pcall(FindService, game, ObjectClassName) -- Generation can and will break when presented with noncreatable Instances such as Path (which is created by PathService:CreateAsync())

			return (not IsService or not Output) and SerializeInstance(ObjectParent)..":WaitForChild("..ObjectName..")" or ServiceGeneration[ObjectClassName] or "game:GetService(\""..ObjectClassName.."\")"
		elseif ObjectClassName == "Model" then
			local Player = Players:GetPlayerFromCharacter(obj)

			return not Player and SerializeInstance(ObjectParent)..":WaitForChild("..ObjectName..")" or "game:GetService(\"Players\")".. (Player == LocalPlayer and ".LocalPlayer.Character" or ":WaitForChild("..ObjectName..").Character")
		end
		return "game:GetService(\"Players\")".. (obj == LocalPlayer and ".LocalPlayer" or ":WaitForChild("..ObjectName..")") 
	end

	return ObjectClassName == "DataModel" and "game" or "Instance.new(\""..ObjectClassName.."\", nil)"
end

local function SerializeVector3(Vector : Vector3)
	return "Vector3.new("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..", "..SerializeNumber(Vector.Z)..")"
end

local function SerializeVector3int16(Vector : Vector3int16)
	return "Vector3int16.new("..Vector.X..", "..Vector.Y..", "..Vector.Z..")"
end

local function SerializeVector2(Vector : Vector2)
	return "Vector2.new("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..")"
end

local function SerializeColor3(Color : Color3)
	return "Color3.new("..SerializeNumber(Color.R)..", "..SerializeNumber(Color.G)..", "..SerializeNumber(Color.B)..")"
end

local function SerializeCFrame(CFrame : CFrame)
	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = CFrame:GetComponents()

	return "CFrame.new("..SerializeNumber(x)..", "..SerializeNumber(y)..", "..SerializeNumber(z)..", "..SerializeNumber(R00)..", "..SerializeNumber(R01)..", "..SerializeNumber(R02)..", "..SerializeNumber(R10)..", "..SerializeNumber(R11)..", "..SerializeNumber(R12)..", "..SerializeNumber(R20)..", "..SerializeNumber(R21)..", "..SerializeNumber(R22)..")"
end

local function SerializeColorSequenceKeypoint(KeyPoint : ColorSequenceKeypoint)
	return "ColorSequenceKeypoint.new("..SerializeNumber(KeyPoint.Time)..", "..SerializeColor3(KeyPoint.Value)..")"
end

local function SerializeNumberSequenceKeypoint(Keypoint : NumberSequenceKeypoint)
	return "NumberSequenceKeypoint.new("..SerializeNumber(Keypoint.Time)..", "..SerializeNumber(Keypoint.Value)..", "..SerializeNumber(Keypoint.Envelope)..")"
end

local function ValidateSharedTableIndex(Index : string)
	local IsKeyword = (type(Index) == "number" and Index or Keywords[Index])

	if not IsKeyword then
		if #Index ~= 0 then
			local IndexBuffer = fromstring(Index)
			local FirstByte = readu8(IndexBuffer, 0)

			if FirstByte >= 97 and FirstByte <= 122 or FirstByte >= 65 and FirstByte <= 90 or FirstByte == 95 then
				local IndexLength = #Index

				for i = 1, IndexLength-1 do
					local Byte = readu8(IndexBuffer, i)

					if not ((Byte >= 97 and Byte <= 122) or (Byte >= 65 and Byte <= 90) or Byte == 95 or (Byte >= 48 and Byte <= 57)) then
						return "["..SerializeString(Index).."] = "
					end
				end
				return Index.." = "
			end

			return "["..SerializeString(Index).."] = "
		end
		return "[\"\"] = "
	end
	return "["..IsKeyword.."] = "
end

local function ValidateIndex(Index : any)
	local IndexType = type(Index)
	local IsNumber = IndexType == "number"	

	if IsNumber or IndexType == "string" then
		local IsKeyword = (IsNumber and Index or Keywords[Index])

		if not IsKeyword then
			if #Index ~= 0 then
				local IndexBuffer = fromstring(Index)
				local FirstByte = readu8(IndexBuffer, 0)

				if FirstByte >= 97 and FirstByte <= 122 or FirstByte >= 65 and FirstByte <= 90 or FirstByte == 95 then
					local IndexLength = #Index

					for i = 1, IndexLength-1 do
						local Byte = readu8(IndexBuffer, i)

						if not ((Byte >= 97 and Byte <= 122) or (Byte >= 65 and Byte <= 90) or Byte == 95 or (Byte >= 48 and Byte <= 57)) then
							return "["..SerializeString(Index).."] = "
						end
					end
					return Index.." = "
				end

				return "["..SerializeString(Index).."] = "
			end
			return "[\"\"] = "
		end

		return "["..IsKeyword.."] = "
	end

	return "["..(IndexType ~= "table" and Serialize(Index, nil, "") or "\"<Table> (table: "..(getmetatable(Index) == nil and tostring(Index):sub(8) or "@Metatable")..")\"").."] = "
end

do
	DataTypes = {
		Axes = function(Axes : Axes)
			return "Axes.new("..concat({
				Axes.X and "Enum.Axis.X" or nil,
				Axes.Y and "Enum.Axis.Y" or nil,
				Axes.Z and "Enum.Axis.Z" or nil
			},", ")..")"
		end,
		BrickColor = function(Color : BrickColor)
			return "BrickColor.new("..Color.Number..")"
		end,
		CFrame = SerializeCFrame,
		Color3 = SerializeColor3,
		ColorSequence = function(Sequence : ColorSequence)
			local Keypoints = Sequence.Keypoints
			local Size = #Keypoints
			local Serialized = ""

			for i = 1,Size-1 do
				Serialized ..= Serialized..SerializeColorSequenceKeypoint(Keypoints[i])..", "
			end

			return "ColorSequence.new({"..Serialized..SerializeColorSequenceKeypoint(Keypoints[Size]).."})"
		end,
		ColorSequenceKeypoint = SerializeColorSequenceKeypoint,
		Content = function(Content : Content)
			local Uri = Content.Uri

			return Uri and "Content.fromUri("..Uri..")" or "Content.none"
		end,
		DateTime = function(Date : DateTime)
			return "DateTime.fromUnixTimestampMillis("..Date.UnixTimestampMillis..")"
		end,
		DockWidgetPluginGuiInfo = function(Dock : DockWidgetPluginGuiInfo)
			local ArgumentFunction = tostring(Dock):gmatch(":([%w-]+)")

			return "DockWidgetPluginGuiInfo.new(Enum.InitialDockState."..ArgumentFunction()..", "..(ArgumentFunction() == "1" and "true" or "false")..", "..(ArgumentFunction() == "1" and "true" or "false")..", "..ArgumentFunction()..", "..ArgumentFunction()..", "..ArgumentFunction()..", "..ArgumentFunction()..")"
		end,
		Enum = Enums,
		EnumItem = function(Item : EnumItem)
			return Enums[Item.EnumType].."."..Item.Name
		end,
		Enums = function()
			return "Enums"
		end,
		Faces = function(Faces : Faces) : string
			return "Faces.new("..concat({
				Faces.Top and "Enum.NormalId.Top" or nil,
				Faces.Bottom and "Enum.NormalId.Bottom" or nil,
				Faces.Left and "Enum.NormalId.Left" or nil,
				Faces.Right and "Enum.NormalId.Right" or nil,
				Faces.Back and "Enum.NormalId.Back" or nil,
				Faces.Front and "Enum.NormalId.Front" or nil,
			}, ", ")..")"
		end,
		FloatCurveKey = function(CurveKey : FloatCurveKey)
			return "FloatCurveKey.new("..SerializeNumber(CurveKey.Time)..", "..SerializeNumber(CurveKey.Value)..", Enum.KeyInterpolationMode."..CurveKey.Interpolation.Name..")"
		end,
		Font = function(Font : Font)
			return "Font.new("..SerializeString(Font.Family)..", Enum.FontWeight."..Font.Weight.Name..", Enum.FontStyle."..Font.Style.Name..")"
		end,
		Instance = SerializeInstance,
		NumberRange = function(Range : NumberRange)
			return "NumberRange.new("..SerializeNumber(Range.Min)..", "..SerializeNumber(Range.Max)..")"
		end,
		NumberSequence = function(Sequence : NumberSequence)
			local Keypoints = Sequence.Keypoints
			local Size = #Keypoints
			local Serialized = ""

			for i = 1,Size-1 do
				Serialized ..= Serialized..SerializeNumberSequenceKeypoint(Keypoints[i])..", "
			end

			return "NumberSequence.new({"..Serialized..SerializeNumberSequenceKeypoint(Keypoints[Size]).."})"
		end,
		NumberSequenceKeypoint = SerializeNumberSequenceKeypoint,
		PathWaypoint = function(Waypoint : PathWaypoint)
			return "PathWaypoint.new("..SerializeVector3(Waypoint.Position)..", Enum.PathWaypointAction."..Waypoint.Action.Name..", "..SerializeString(Waypoint.Label)..")"
		end,
		PhysicalProperties = function(Properties : PhysicalProperties)
			return "PhysicalProperties.new("..(nanToString(Properties.Density))..", "..nanToString(Properties.Friction)..", "..nanToString(Properties.Elasticity)..", "..nanToString(Properties.FrictionWeight)..", "..nanToString(Properties.ElasticityWeight)..")"
		end,
		RBXScriptConnection = function(Connection : RBXScriptConnection)
			return "(nil --[[ RBXScriptConnection | IsConnected: "..(Connection.Connected and "true" or "false").." ]])" -- Can't support this
		end,
		RBXScriptSignal = function(Signal : RBXScriptSignal) : string
			local SignalName = tostring(Signal):match("Signal (%a+)")

			return Signals[SignalName] or "(nil --[[ RBXScriptSignal | "..SignalName.." is not supported ]])"
		end,
		Random = function()
			return "(Random.new() --[[Random cant be supported because I cant get the seed]])"
		end,
		Ray = function(Ray : Ray)
			return "Ray.new("..SerializeVector3(Ray.Origin)..", "..SerializeVector3(Ray.Direction)..")"
		end,
		Rect = function(Rect : Rect)
			return "Rect.new("..SerializeVector2(Rect.Min)..", "..SerializeVector2(Rect.Max)..")"
		end,
		Region3 = function(Region : Region3)
			local Center = Region.CFrame.Position
			local Size = Region.Size/2

			return "Region3.new("..SerializeVector3(Center - Size)..", "..SerializeVector3(Center + Size)..")"
		end,
		Region3int16 = function(Region : Region3int16)
			return "Region3int16.new("..SerializeVector3int16(Region.Min)..", "..SerializeVector3int16(Region.Max)..")"
		end,
		RotationCurveKey = function(Curve : RotationCurveKey)
			return "RotationCurveKey.new("..SerializeNumber(Curve.Time)..", "..SerializeCFrame(Curve.Value)..", Enum.KeyInterpolationMode."..Curve.Interpolation.Name..")"
		end,
		SharedTable = function(Shared : SharedTable, format : boolean?, indents : string)
			local isreadonly = IsSharedFrozen(Shared)

			if SharedSize(Shared) ~= 0 then
				local stackindent = indents..(format and "\t" or "")
				local CurrentIndex = 1
				local Serialized = {}

				for i,v in Shared do
					Serialized[CurrentIndex] = (CurrentIndex ~= i and ValidateSharedTableIndex(i) or "")..Serialize(v, format, stackindent)
					CurrentIndex += 1	
				end

				local formatspace = format and "\n" or ""
				local Contents = formatspace..stackindent..concat(Serialized, (format and ",\n" or ", ")..stackindent)..formatspace..indents

				return not isreadonly and "SharedTable.new({"..Contents.."})" or "SharedTable.cloneAndFreeze(SharedTable.new({"..Contents.."}))"
			end
			return not isreadonly and "SharedTable.new()" or "SharedTable.cloneAndFreeze(SharedTable.new())"
		end,
		TweenInfo = function(Info : TweenInfo)
			return "TweenInfo.new("..SerializeNumber(Info.Time)..", Enum.EasingStyle."..Info.EasingStyle.Name..", Enum.EasingDirection."..Info.EasingDirection.Name..", "..Info.RepeatCount..", "..(Info.Reverses and "true" or "false")..", "..SerializeNumber(Info.DelayTime)..")"
		end,
		UDim = function(UDim : UDim)
			return "UDim.new("..SerializeNumber(UDim.Scale)..", "..UDim.Offset..")"
		end,
		UDim2 = function(UDim2 : UDim2)
			local Width = UDim2.X
			local Height = UDim2.Y

			return "UDim2.new("..SerializeNumber(Width.Scale)..", "..Width.Offset..", "..SerializeNumber(Height.Scale)..", "..Height.Offset..")"
		end,
		Vector2 = SerializeVector2,
		Vector2int16 = function(Vector : Vector2int16)
			return "Vector2int16.new("..Vector.X..", "..Vector.Y..")"
		end,
		Vector3 = SerializeVector3,
		Vector3int16 = function(Vector : Vector3int16)
			return "Vector3int16.new("..Vector.X..", "..Vector.Y..", "..Vector.Z..")"
		end,
		boolean = function(bool : boolean)
			return bool and "true" or "false"
		end,
		buffer = function(buff : buffer)
			return "buffer.fromstring("..SerializeString(bufftostring(buff))..")"
		end,
		["function"] = function(Function, format : boolean?, indents : string)
			local IsGlobal = Globals[Function]

			if not IsGlobal then
				if format then
					local tempindents = indents.."\t\t\t"
					local source, line, name, numparams, vargs = info(Function, "slna")
					local Serialized = "source = "..SerializeString(source)..",\n"..tempindents.."line = "..line..",\n"..tempindents.."what = "..(line ~= -1 and "\"Lua\"" or "\"C\"")..",\n"..tempindents.."name = "..name..",\n"..tempindents.."numparams = "..numparams..",\n"..tempindents.."vargs = "..(vargs and "true" or "false")..",\n"..tempindents.."function = "..tostring(Function)

					return "function()\n\t"..indents.."--[[\n\t\t"..indents.."info = {\n"..tempindents..Serialized.."\n\t\t"..indents.."}\n\t"..indents.."]]\n"..indents.."end" -- @TODO grab function from globals/add function info using the getinfo i made
				end

				return info(Function, "l") ~= -1 and "function() end" or "(nil --[[ CClosure ]])" -- shouldn't really ever be possible unless lego hax newcclosure
			end
			return IsGlobal
		end,
		["nil"] = function()
			return "nil"
		end,
		number = SerializeNumber,
		string = SerializeString,
		table = function(tbl : {[any] : any}, format : boolean?, indents : string, CyclicList) : string
			local isreadonly = isfrozen(tbl)

			if next(tbl) ~= nil then
				local CyclicList, Created = GetCyclicTables(tbl), CyclicList ~= nil or nil
				local stackindent = indents..(format and "\t" or "")
				local CurrentIndex = 1
				local Serialized = {}

				for i,v in next, tbl do
					Serialized[CurrentIndex] = (CurrentIndex ~= i and ValidateIndex(i) or "")..Serialize(v, format, stackindent, CyclicList)
					CurrentIndex += 1
				end

				local formatspace = format and "\n" or ""
				local Contents = formatspace..stackindent..concat(Serialized, (format and ",\n" or ", ")..stackindent)..formatspace..indents

				return not isreadonly and "{"..Contents.."}" or "table.freeze({"..Contents.."})"
			end

			return not isreadonly and "{}" or "table.freeze({})"
		end,
		thread = function(thread : thread) -- planning on adding more to this
			return "coroutine.create(function() end)"
		end,
		userdata = function(userdata : any) -- planning on adding more to this later
			return getmetatable(userdata) ~= nil and "newproxy(true)" or "newproxy(false)"
		end
	}
end

local function Serializevargs(... : any) : string
	local generation = ""
	local tbl = {...}
	local arraysize = #tbl

	for i,v in tbl do
		generation ..= Serialize(v, true, "")..(i ~= arraysize and " " or "")

		if #generation > 100000 then -- output functions will trim the output
			break
		end
	end

	return generation
end

function SerializeClass.SerializeKnown(DataType : string, DataStructure : any?, format : boolean?)
	local SerializeMethod = DataTypes[DataType]

	assert(SerializeMethod, "Attempted to use unsupported DataType")

	return SerializeMethod(DataStructure, format, "")
end

function SerializeClass.print(... : any?)
	print(Serializevargs(...))
end

function SerializeClass.warn(... : any?)
	warn(Serializevargs(...))
end

function SerializeClass.Serialize(data : any?, format : boolean?)
	return Serialize(data, format, "")
end

function SerializeClass.output(data : any?, format : boolean?) : ()
	if IsStudio then
		local ScriptEditor = game:GetService("ScriptEditorService")
		local Storage = game:FindFirstChild("Serialized_Storage") or (function() : Folder
			local Folder = Instance.new("Folder", game)
			Folder.Name = "Serialized_Storage"
			return Folder
		end)()

		function SerializeClass.output(data : any?, format : boolean?) : ()
			local Serialized = SerializeClass.Serialize(data, format)
			local DisplayScript = Instance.new("LocalScript", Storage)
			DisplayScript.Name = "Serialized_"..math.floor(os.clock())

			ScriptEditor:UpdateSourceAsync(DisplayScript, function()
				return Serialized
			end)

			ScriptEditor:OpenScriptDocumentAsync(DisplayScript)
		end
		SerializeClass.output(data, format)
	else
		warn(debug.traceback("Cannot display output when not in studio:"))
	end
end

SerializeClass._Serialize = Serialize
return setmetatable({}, {__index = SerializeClass})
