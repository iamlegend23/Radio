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
	print("Confirm "..activator:Nick())
	net.Start("Radio-Use")
		net.WriteEntity(self)
	net.Send(activator)
end

net.Receive("SendURL", function( len, ply)
	local URL=net.ReadString()
	local ent=net.ReadEntity()
	print("Received from client "..URL)
		net.Start("BroadcastURL")
			net.WriteString(URL)
			net.WriteEntity(ent)
			print("Sent "..URL)
		net.Broadcast()
end)

