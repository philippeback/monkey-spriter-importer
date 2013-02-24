#TEXT_FILES="*.txt|*.xml|*.json|*.SCML|*.scml"
Strict
Import mojo
Import spriterImporter

Function Main:Int()
	New Game()
	Return 0
End

'-------------------------- Monkey Spriter Demo --------------------------
Class Game Extends App
	
	Field monster:MonkeySpriter
	Field hero:MonkeySpriter
	Field bones:MonkeySpriter
	
	Const IDLE:String = "Idle"
	Const POSTURE:String = "Posture"
	Field monsterAnimName:String = IDLE
	
	Const IDLEH:String = "idle_healthy"
	Const WALK:String = "walk"
	Field heroAnimName:String = IDLEH
	
	Const IDLEB:String = "Player_Idle"
	Const WALKB:String = "Player_Walk"
	Field boneAnimName:String = IDLEB
	
	Field flipX:Bool
	Field flipY:Bool
	Field lastMillisecs:Int
	Field currentMillisecs:Int 
	Field timeElapsed:Int
	Field frameCounter:Int
	Field fpsCounter:Int
	Field frameTimer:Int
	Field tween:Bool = True
	Field loopType:Int
	Field scaleX:Float = 1
	Field scaleY:Float = 1
	Field debug:Bool
	
	Method OnCreate:Int()
		monster = SpriterImporter.ImportFile("monster", "Example.SCML", "monster\monster.xml")
		hero = SpriterImporter.ImportFile("example hero", "BetaFormatHero.SCML")
		bones = SpriterImporter.ImportFile("BoneExample", "Basic_Platformer.scml")
		
		monster.x = DeviceWidth() / 2
		monster.y = DeviceHeight() - 20
		hero.x = DeviceWidth() / 2 - 200
		hero.y = DeviceHeight() - 20
		bones.x = DeviceWidth() / 2 + 200
		bones.y = DeviceHeight() - 20
		
		bones.timer.Start()
		monster.timer.Start()
		hero.timer.Start()		
		SetUpdateRate(60)
		lastMillisecs = Millisecs()
		loopType = MonkeySpriter.LOOPING_TRUE
		debug = false
		CreateGUI()
		Seed = Millisecs()
		Return 0
	End
	
	Method CreateGUI:Void()
		Local b:Button = New Button("Anim 1", 0, 10, 100, 20)
		b.SetColour(255, 0, 0)
		b = New Button("Anim 2", 110, 10, 100, 20)

		b = New Button("Loop Type", 220, 10, 100, 20)
		b.SetColour(255, 255, 0)
		
		b = New Button("Reset Timer", 330, 10, 100, 20)
		b.SetColour(255, 0, 255)
		
		b = New Button("Stop Timer", 440, 10, 100, 20)
		b.SetColour(0, 255, 255)
		
		b = New Button("Resume Timer", 550, 10, 100, 20)
		b.SetColour(0, 255, 0)
		
		b = New Button("Slower", 440, 40, 100, 20)
		b.SetColour(100, 100, 100)
		
		b = New Button("Faster", 550, 40, 100, 20)
		b.SetColour(0, 0, 255)
		
		b = New Button("Tween On/Off", 330, 40, 100, 20)
		b.SetColour(25, 255, 25)

		b = New Button("Flip X", 0, 70, 100, 20)
		b.SetColour(25, 255, 125)	

		b = New Button("Flip Y", 110, 70, 100, 20)
		b.SetColour(123, 123, 255)	

		b = New Button("Scale Up", 0, 40, 100, 20)
		b.SetColour(255, 33, 125)	
		
		b = New Button("Scale Down", 110, 40, 100, 20)
		b.SetColour(125, 0, 125)
		
		b = New Button("Debug On/Off", 220, 40, 100, 20)
		b.SetColour(125, 230, 234)
		
		b = New Button("Benchmark", 220, 70, 100, 20)
		b.SetColour(240, 230, 234)
			
		b = New Button("Clear BM", 330, 70, 100, 20)
		b.SetColour(240, 23, 234)	
	End
	
	Method OnUpdate:Int()
		CalcFPS()
		
		hero.Update(heroAnimName, loopType, timeElapsed)
		monster.Update(monsterAnimName, loopType, timeElapsed)
		bones.Update(boneAnimName, loopType, timeElapsed)
		Monster.UpdateAll(timeElapsed)

		Controls()
		Return 0
	End	
	
	Method CalcFPS:Void()
		' simple delta timing
		currentMillisecs = Millisecs()
		timeElapsed = currentMillisecs - lastMillisecs 
		lastMillisecs = currentMillisecs

		' simple fps counter
		If Millisecs() < frameTimer + 1000
			frameCounter+=1
		Else
			fpsCounter = frameCounter
			frameCounter = 0
			frameTimer = Millisecs()
		End
	End
	
	Method OnRender:Int()
		Cls
		monster.Draw(tween)
		Monster.DrawAll(tween)
		bones.Draw(tween)
		hero.Draw(tween)
		Button.DrawAll()
		If debug Then DrawDebug()
		DrawText("FPS: " + fpsCounter + " with " + (3 + Monster.list.Count()) + " objects", 2, DeviceHeight() - 12)
		Return 0
	End
	
	Method Controls:Void()
		Button.UpdateAll()
		If Button.Clicked("Debug On/Off") Then
			debug = Not debug
		End
		If Button.Clicked("Scale Up") Then
			scaleX *= 1.1
			scaleY *= 1.1
			monster.SetScale(scaleX, scaleY)
			hero.SetScale(scaleX, scaleY)
			For Local m:Monster = Eachin Monster.list
				m.spriter.SetScale(scaleX, scaleY)
			End
			bones.SetScale(scaleX, scaleY)
		End
		If Button.Clicked("Scale Down") Then
			scaleX /= 1.1
			scaleY /= 1.1
			monster.SetScale(scaleX, scaleY)
			hero.SetScale(scaleX, scaleY)
			For Local m:Monster = Eachin Monster.list
				m.spriter.SetScale(scaleX, scaleY)
			End
			bones.SetScale(scaleX, scaleY)
		End
		If Button.Clicked("Flip X") Then
			scaleX = -scaleX
			monster.SetScale(scaleX, monster.scaleY)
			hero.SetScale(scaleX, monster.scaleY)
			For Local m:Monster = Eachin Monster.list
				m.spriter.SetScale(scaleX, m.spriter.scaleY)
			End
			bones.SetScale(scaleX, bones.scaleY)
		End
		
		If Button.Clicked("Flip Y") Then
			scaleY = -scaleY
			monster.SetScale(monster.scaleX, scaleY)
			hero.SetScale(hero.scaleX, scaleY)
			monster.y = DeviceHeight() - monster.y
			hero.y = DeviceHeight() - hero.y
			For Local m:Monster = Eachin Monster.list
				m.spriter.SetScale(m.spriter.scaleX, scaleY)
			End
			bones.SetScale(bones.scaleX, scaleY)
			bones.y = DeviceHeight() - bones.y
		End
		If Button.Clicked("Stop Timer") Then
			monster.timer.Stop()
			hero.timer.Stop()
			bones.timer.Stop()
			For Local m:Monster = Eachin Monster.list
				m.spriter.timer.Stop()
			End
		End
		If Button.Clicked("Resume Timer") Then
			monster.timer.Resume()
			hero.timer.Resume()
			bones.timer.Resume()
			For Local m:Monster = Eachin Monster.list
				m.spriter.timer.Resume()
			End
		End
		If Button.Clicked("Reset Timer") Then
			monster.timer.Start()
			hero.timer.Start()
			bones.timer.Start()
			monster.mainlineKeyId = 0
			hero.mainlineKeyId = 0
			bones.mainlineKeyId = 0
			For Local m:Monster = Eachin Monster.list
				m.spriter.timer.Start()
				m.spriter.mainlineKeyId = 0
			End
		End
		If Button.Clicked("Faster") Then
			hero.timer.rate/=1.1
			monster.timer.rate/=1.1
			For Local m:Monster = Eachin Monster.list
				m.spriter.timer.rate/=1.1
			End
			bones.timer.rate/=1.1
		End
		If Button.Clicked("Slower") Then
			hero.timer.rate*=1.1
			monster.timer.rate*=1.1
			For Local m:Monster = Eachin Monster.list
				m.spriter.timer.rate*=1.1
			End
			bones.timer.rate*=1.1
		End
		If Button.Clicked("Anim 1") Then
			monsterAnimName = IDLE
			heroAnimName = IDLEH
			monster.mainlineKeyId = 0
			monster.timer.Start()
			hero.mainlineKeyId = 0
			hero.timer.Start()
			For Local m:Monster = Eachin Monster.list
				m.animationName = IDLE
			End
			boneAnimName = IDLEB
			bones.mainlineKeyId = 0
			bones.timer.Start()			
		End
		If Button.Clicked("Anim 2") Then
			monsterAnimName = POSTURE
			heroAnimName = WALK
			monster.mainlineKeyId = 0
			monster.timer.Start()
			hero.mainlineKeyId = 0
			hero.timer.Start()
			For Local m:Monster = Eachin Monster.list
				m.animationName = POSTURE
			End
			boneAnimName = WALKB
			bones.mainlineKeyId = 0
			bones.timer.Start()
		End
		If Button.Clicked("Tween On/Off") Then
			tween = Not tween
		End
		If Button.Clicked("Loop Type") Then
			monster.timer.Start()
			hero.timer.Start()
			bones.timer.Start()
			monster.mainlineKeyId = 0
			hero.mainlineKeyId = 0
			bones.mainlineKeyId = 0
			loopType += 1
			If loopType > 2 loopType = 0
			For Local m:Monster = Eachin Monster.list
				m.loopType = loopType
				m.spriter.timer.Start()
				m.spriter.mainlineKeyId = 0
			End
		End
		
		If Button.Clicked("Benchmark") Then	
			Seed = Millisecs()
			For Local i:Int = 0 To 100
				Local m:Monster = New Monster()
				m.spriter = monster.Copy()
				m.spriter.x = Rnd(0, DeviceWidth())
				m.spriter.y = Rnd(0, DeviceHeight())
				m.spriter.timer.Start()
				m.spriter.SetScale(.5, .5)
			Next
		End
		If Button.Clicked("Clear BM") Then
			Monster.list.Clear()
		End
		If KeyDown(KEY_W) hero.y-=2
		If KeyDown(KEY_S) hero.y+=2
		If KeyDown(KEY_A) hero.x-=2
		If KeyDown(KEY_D) hero.x+=2
	End
	
	Method DrawDebug:Void()
		Local y:Int = 100
		Local gap:Int = 15
		SetAlpha(0.75)
		DrawText("MONKEY SPRITER IMPORTER", 10, y)
		y+=gap
		y+=gap
		DrawText("Monster Timer = " + monster.timer.GetTime(), 10, y)
		y+=gap
		DrawText("Hero Timer    = " + hero.timer.GetTime(), 10, y)
		y+=gap
		DrawText("Time Elapsed  = " + timeElapsed, 10, y)
		y+=gap
		Local loopString:String
		Select loopType
			Case 0
				loopString = "FALSE"
			Case 1
				loopString = "TRUE"
			Case 2
				loopString = "PING PONG"
		End
		DrawText("Looping Type  = " + loopString, 10, y)
		y+=gap
		DrawText("Timer Rate    = " + monster.timer.rate, 10, y)
		y+=gap
		If tween
			DrawText("Tweening      = TRUE", 10, y)
		Else
			DrawText("Tweening      = FALSE", 10, y)
		End
		y+=gap
		DrawText("Scale X       = " + scaleX, 10, y)
		y+=gap
		DrawText("Scale Y       = " + scaleY, 10, y)

		SetAlpha(1)
	End
End

Class Monster
	Global list:List<Monster> = New List<Monster>
	Field spriter:MonkeySpriter
	Field animationName:String
	Field loopType:Int = MonkeySpriter.LOOPING_TRUE
	
	Method New()
		animationName = "Idle"
		Self.list.AddLast(Self)
	End
	
	Method Draw:Void(tween:Bool)
		spriter.Draw(tween)
	End
	
	Method Update:Void(dt:Float)
		spriter.Update(animationName, loopType, dt)
	End
	
	Function UpdateAll:Void(dt:Float)
		For Local m:Monster = Eachin Monster.list
			m.Update(dt)
		Next
	End
	
	Function DrawAll:Void(tween:Bool)
		For Local m:Monster = Eachin Monster.list
			m.Draw(tween)
		Next
	End
End

'-------------------------- Simple Button --------------------------
Class Button
	Field x:Int, y:Int
	Field w:Int, h:Int
	Field label:String
	Field name:String
	Field r:Int = 255, g:Int = 255, b:Int = 255
	Field mouseOver:Bool = False
	Field clicked:Bool = False
	Global clickedName:String = ""
	Global list:List<Button>
	
	Method New(label:String, x:Int, y:Int, w:Int, h:Int)
		If list = Null Then list = New List<Button>
		Self.label = label
		Self.name = label.ToUpper()
		Self.x = x
		Self.y = y
		Self.w = w
		Self.h = h
		
		list.AddLast(Self)
	End
	
	Method SetColour:Void(r:Int, g:Int, b:Int)
		Self.r = r
		Self.g = g
		Self.b = b
	End
	
	Method Update:Void()
		If RectsOverlap(MouseX(), MouseY(), 3, 3, Self.x, Self.y, Self.w, Self.h)
			mouseOver = True
			If MouseHit(MOUSE_LEFT)
				If Not clicked
					clicked = True
				End
			Else
				clicked = False
			End
		Else
			clicked = False
			mouseOver = False
		End
	End
	
	Method Draw:Void()
		Local light:Int = -25
		If mouseOver
			light = 120
			SetAlpha(1)
		End
		SetColor (r + light, g + light, b + light)
		DrawRect (x, y, w, h)
		SetColor (255, 255, 255)
		DrawText (label, x + 2, y + 2)
	End
	
	Function DrawAll:Void()
		For Local b:Button = Eachin list
			SetAlpha(0.75)
			b.Draw()
		End
		SetAlpha(1)		
	End
	
	Function Clicked:Int(name:String)
		name = name.ToUpper()
		If name = clickedName
			clickedName = ""
			Return 1		
		Else
			Return 0
		End
	End
	
	Function UpdateAll:Void()
		clickedName = ""
		For Local b:Button = Eachin list
			b.Update()
			If b.clicked Then clickedName = b.name
		End
	End
End

'-------------------------- Functions --------------------------
Function RectsOverlap:Int(x0:Float, y0:Float, w0:Float, h0:Float, x2:Float, y2:Float, w2:Float, h2:Float)
	If x0 > (x2 + w2) Or (x0 + w0) < x2 Then Return False
	If y0 > (y2 + h2) Or (y0 + h0) < y2 Then Return False
	Return True
End