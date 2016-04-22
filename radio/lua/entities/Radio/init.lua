AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

util.AddNetworkString( "Radio-Use" )
util.AddNetworkString( "SendURL" )
util.AddNetworkString( "BroadcastURL" )

function ENT:SpawnFunction( ply, tr ) 
	if ( !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 55
	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:PhysWake()
	return ent
end

function ENT:Initialize()
	self:SetModel("models/props_lab/citizenradio.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType(SIMPLE_USE)
end


function ENT:Use( activator, caller )
	net.Start("Radio-Use")
		net.WriteEntity(self)
	net.Send(activator)
end

local patterns={
	"youtu.be/([_A-Za-z0-9-]+)",
	"youtube.com/watch%?v=([_A-Za-z0-9-]+)",
}
local api="https://abyss.mattjeanes.com:8090/"
function ENT:ResolveMusicURL(url,callback)
	if url:find("youtu.be") or url:find("youtube.com") then
		local id=string.match(url,patterns[1]) or string.match(url,patterns[2])
		if id then
			http.Fetch(api.."get?id="..id,
				function(body,len,headers,code)
					local tbl=util.JSONToTable(body)
					if tbl then
						if tbl.success then
							callback(null,(api.."play?id="..id))
						else
							callback("Failed to load ("..(tbl.err and tbl.err or "Unknown reason")..")")
						end
					else
						callback("Failed to load API response")
					end
				end,
				function(err)
					callback("Failed to resolve url ("..err..")")
				end
			)
		else
			callback("Couldn't find video ID inside url")
		end
	else
		callback(nil,url)
	end
end

net.Receive("SendURL", function(len, ply)
	local url=net.ReadString()
	local ent=net.ReadEntity()
	if ent.ResolveMusicURL then
		ent:ResolveMusicURL(url,function(err,url)
			if err then
				ply:ChatPrint("ERROR: "..err)
			else
				ply:ChatPrint("Playing!")
				net.Start("BroadcastURL")
					net.WriteString(url)
					net.WriteEntity(ent)
				net.Broadcast()
			end
		end)
	end
end)

