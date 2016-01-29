include('shared.lua')

local SSV, RMV , ETV

surface.CreateFont("Radio", {font="Tahoma", size=48, weight=700, shadow=true})

function ENT:Draw()

    self:DrawModel()
	local pos = self:LocalToWorld(Vector(0,0,45))
	local ang = self:GetAngles()
	local right = ang:Right()
	local dir = ang:Forward():Angle()
	
	dir:RotateAroundAxis(dir:Right(), -90)
	dir:RotateAroundAxis(dir:Up(), 90)
	
	cam.Start3D2D(pos, dir, 0.1 )
		draw.DrawText("Radio", "Radio", 0, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
	cam.End3D2D()
	
			--Visualizer
	if IsValid(self.stream) && self.stream:GetState()==GMOD_CHANNEL_PLAYING then 
		cam.Start3D2D( self:LocalToWorld(Vector(10,-13,2)), self:LocalToWorldAngles(Angle(0,90,90)), 0.07 )
			for I=1, 180 do 	
				surface.SetDrawColor(self.tbl[I]*1500,255,0,255)
				surface.DrawOutlinedRect(I*2,0,3,-self.tbl[I]*800) 
			end 
		cam.End3D2D()
		if RMV > 0 then
			if halo.RenderedEntity()~=self then
				DrawBloom( 0.2,self.tbl[2], 9, 9, 1, 1, self.tbl[2]*RMV, self.tbl[5]*RMV, self.tbl[10]*RMV ) -- Need to get this to work inside an alternate function
			end
		end
	end	
	
end

function ENT:Think()

	if IsValid(self.stream) && self.stream:GetState()==GMOD_CHANNEL_PLAYING then 
			self:FFT()
			--SFX Stuff--
		if SSV > 0 then
			if self.tbl[2] > 0.075 then
				util.ScreenShake( self:GetPos(),self.tbl[2]*SSV, 10, 0.5, 50 )
			end
		end
	end 
	
	if !ETV && IsValid(self.stream) then 
		self.stream:Stop()
	end
	
	SSV = math.Clamp(GetConVar("ScreenShakeValue"):GetFloat(),0,5)
	RMV = math.Clamp(GetConVar("RaveModeValue"):GetFloat(),0,20)
	ETV = GetConVar("RadioToggle"):GetBool()
	
end

function ENT:Input()
	
	local Frame = vgui.Create( "DFrame" )
	Frame:SetTitle( "Radio" )
	Frame:SetSize( 300, 300 )
	Frame:Center()
	Frame:MakePopup()
	Frame.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 100, 100, 100, 200 ) ) 
	
	end

	local URLEntry = vgui.Create( "DTextEntry", Frame )
	URLEntry:SetPos( 25, 50 )
	URLEntry:SetSize( 250, 35 )
	URLEntry:SetText( "URL" )
	
	local URLButton = vgui.Create( "DButton", Frame ) -- URL Button
	URLButton:SetText( "Play/Stop" )
	URLButton:SetTextColor( Color( 255, 255, 255 ) )
	URLButton:SetPos( 100, 100 )
	URLButton:SetSize( 100, 30 )
	URLButton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 41, 128, 185, 250 ) ) 
	end	
	
	local UpdateButton = vgui.Create( "DButton", Frame ) -- Update Button
	UpdateButton:SetText( "Update Settings" )
	UpdateButton:SetTextColor( Color( 255, 255, 255 ) )
	UpdateButton:SetPos( 100, 250 )
	UpdateButton:SetSize( 100, 30 )
	UpdateButton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 41, 128, 185, 250 ) ) 
	end

	local EnableTog = vgui.Create( "DCheckBox",Frame )
	EnableTog:SetPos( 120, 150 )
	EnableTog:SetValue( 0 )
	EnableTog:SetConVar( "RadioToggle" )
	
	local ScreenShakeMag = vgui.Create( "Slider", Frame )
	ScreenShakeMag:SetPos( 120, 175 )
	ScreenShakeMag:SetSize( 150, 20 )
	ScreenShakeMag:SetMin( 0 )				 
	ScreenShakeMag:SetMax( 5 )	
	ScreenShakeMag:SetConVar( "ScreenShakeValue" )
	
	local RaveModeMag = vgui.Create( "Slider", Frame )
	RaveModeMag:SetPos( 120, 200 )
	RaveModeMag:SetSize( 150, 20 )
	RaveModeMag:SetMin( 0 )				 
	RaveModeMag:SetMax( 20 )	
	RaveModeMag:SetConVar( "RaveModeValue" )
	
	local ETT = vgui.Create( "DLabel", Frame )
	ETT:SetSize( 100, 20 )
	ETT:SetPos( 20, 150 )
	ETT:SetText( "Enable:" )
	
	local SST = vgui.Create( "DLabel", Frame )
	SST:SetSize( 100, 20 )
	SST:SetPos(20, 175 )
	SST:SetText( "ScreenShake Value:" )
		
	local RMT = vgui.Create( "DLabel", Frame )
	RMT:SetSize( 100, 20 )
	RMT:SetPos( 20, 200 )
	RMT:SetText( "Rave Value:" )
	
	URLButton.DoClick = function()
		local EnteredURL = URLEntry:GetValue()
		net.Start("SendURL")
				net.WriteString(EnteredURL)
				net.WriteEntity(self)
			net.SendToServer()
		Frame:Close()	
	end
	
	UpdateButton.DoClick = function()
		SSV = GetConVar("ScreenShakeValue"):GetFloat()
		RMV = GetConVar("RaveModeValue"):GetFloat()
		ETV = GetConVar("RadioToggle"):GetBool()
	end
end

function ENT:Initialize() 
	self.tbl={}
end 

net.Receive("Radio-Use", function()
	local e=net.ReadEntity()
	if IsValid(e) and e.Input then
		e:Input()
	end
end)

net.Receive("BroadcastURL", function()
	local BroadcastedURL=net.ReadString()
	local BroadcastedEnt=net.ReadEntity()
	if IsValid(BroadcastedEnt.stream) then 
		BroadcastedEnt.stream:Stop()
	end
	if ETV then
		sound.PlayURL( BroadcastedURL, "mono", function(stream)
			BroadcastedEnt.stream=stream
		end)
	end
end)	

function ENT:OnRemove()
	if IsValid(self.stream) then 
		self.stream:Stop()
	end
end	

function ENT:FFT()
	if self.stream:GetState()==GMOD_CHANNEL_PLAYING then
		self.stream:FFT(self.tbl,FFT_512)--Get FFT Data, 512 = 256 Samples 
	end
end

CreateClientConVar( "RadioToggle", "0", true, false )
CreateClientConVar( "ScreenShakeValue", "2", true, false )
CreateClientConVar( "RaveModeValue", "5", true, false )