#TEXT_FILES="*.txt|*.xml|*.json|*.SCML"
Strict

Import diddy

Function Main:Int()
	New Game()
	Return 0
End

Class Game Extends App
	Field spriterObject:SpriterObject
	Field timeElapsed:Float = 0
	Field textures:TextureProvider
	
	Method OnCreate:Int()
		textures = New TextureProvider
		spriterObject = SpriterImporter.ImportFile("hero/BetaFormatHero.SCML", textures)
		
		SetUpdateRate(60)
		Return 0
	End
	Method OnUpdate:Int()
		Return 0
	End	
	Method OnRender:Int()
		Cls(255, 0, 255)
		timeElapsed+=0.06 'dx.graphics.getDeltaTime();
		SpriterDrawer.Draw(textures, spriterObject, "idle_healthy", timeElapsed*100 Mod 760, 100, 300);
	    SpriterDrawer.Draw(textures, spriterObject, "walk", timeElapsed*100 Mod 225, 300, 300);

		Return 0
	End
End

Class SpriterAnimation
	Field name:String
	Field frames:ArrayList<SpriterAnimationFrame>
	
	Method New()
		Self.frames = New ArrayList<SpriterAnimationFrame>
	End
	
	Method GetFrames:ArrayList<SpriterAnimationFrame>()
		Return Self.frames
	End
	
	Method AddFrame:Void(frame:SpriterAnimationFrame)
		Self.frames.Add(frame)
	End
	
	Method ToString:String()
		Return "";'"SpriterAnimation [name=" + name + ", frames=" + frames + "]"
	End
End

Class SpriterAnimationFrame
	Field frame:SpriterFrame
	Field duration:Float
	
	Method ToString:String()
		Return "SpriterAnimationFrame [frame=" + frame + ", duration=" + duration + "]"
	End	
End

Class SpriterFrame
	Field name:String
	Field sprites:ArrayList<SpriterSprite>
	
	Method New()
		Self.sprites = New ArrayList<SpriterSprite>
	End
	
	Method GetSprites:ArrayList<SpriterSprite>()
		Return Self.sprites
	End
	
	Method AddSprite:Void(sprite:SpriterSprite)
		Self.sprites.Add(sprite)
	End
	
	Method GetSpriteByObjectPart:SpriterSprite(objectPart:SpriterObjectPart)
		For Local i:Int = 0 To sprites.Size() -1
			Local sprite:SpriterSprite = sprites.Get(i)
			If sprite.objectPart = objectPart
				Return sprite
			End
		Next
		Return Null
	End
	
	Method GetSpriteByObjectPartPath:SpriterSprite(objectPart:SpriterObjectPart)
		'TODO
		Local searchPath:String = "" 'objectPart.textureName.substring(0, objectPart.textureName.indexOf("\\"));

		For Local i:Int = 0 To sprites.Size() - 1
			Local sprite:SpriterSprite = sprites.Get(i)
			Local curPath:String = ""'sprite.objectPart.textureName.substring(0, sprite.objectPart.textureName.indexOf("\\"));    		
    		
			If curPath = searchPath
				Return sprite
			End
		Next
		Return Null
	End
	
	Method ToString:String()
		Return ""'"SpriterFrame [name=" + name + ", sprites=" + sprites + "]"
	End	
End

Class SpriterObject
	Field basePath:String

	Field objectParts:StringMap<SpriterObjectPart>
	Field animations:StringMap<SpriterAnimation>
	
	Method New()
		Self.objectParts = New StringMap<SpriterObjectPart>
		Self.animations = New StringMap<SpriterAnimation>
	End
	
	Method GetObjectParts:StringMap<SpriterObjectPart>()
		Return objectParts
	End

	Method AddObjectPart:Void(objectPart:SpriterObjectPart)
		Self.objectParts.Add(objectPart.textureName, objectPart)
	End

	Method GetAnimations:StringMap<SpriterAnimation>()
		Return animations
	End

	Method AddAnimation:Void(animation:SpriterAnimation)
		Self.animations.Add(animation.name, animation)
	End

	Method ToString:String()
		Return ""'"SpriterObject [objectParts=" + objectParts + ", animations=" + animations + "]"
	End
End

Class SpriterObjectPart
	Field textureName:String
	Field originX:Float
	Field originY:Float
	
	Method ToString:String()
		Return ""'"SpriterObjectPart [textureName=" + textureName + ", originX=" + originX + ", originY=" + originY + "]"
	End
End

Class SpriterSprite
	Field objectPart:SpriterObjectPart
	Field colorBits:Float
	Field opacity:Float
	Field angle:Float
	Field x:Float
	Field y:Float
	Field width:Float
	Field height:Float

	Method ToString:String()
		Return ""'"SpriterSprite [objectPart=" + objectPart + ", colorBits=" + colorBits + ", opacity=" + opacity + ", angle=" + angle + ", x=" + x + ", y=" + y + ", width=" + width + ", height=" + height + "]"
	End
End

Class SpriterImporter
	Function ImportFile:SpriterObject(file:String, textures:TextureProvider)
		Local xmlReader:XMLParser = New XMLParser
		Local doc:XMLDocument = xmlReader.ParseString(LoadString(file))
		
		Print doc.Root.Children.Get(0).Parent.Name
		
		
		Local rootElement:XMLElement = doc.Root
		Local spriterObject:SpriterObject = New SpriterObject
		
		spriterObject.basePath = "hero\" 'file.path().replace(file.name(), "");
		'// import the objectParts with the hotspots
		
		Local xmlHotSpotArray:XMLElement = rootElement.GetFirstChildByName("hotspotarray")
		If (xmlHotSpotArray<>Null) Then
			For Local xmlHotSpot:XMLElement = Eachin xmlHotSpotArray.GetChildrenByName("hotspot")
				Local objectPart:SpriterObjectPart = New SpriterObjectPart
				objectPart.textureName = xmlHotSpot.GetFirstChildByName("filepath").Value()
				objectPart.originX = Float(xmlHotSpot.GetFirstChildByName("x").Value())
				objectPart.originY = Float(xmlHotSpot.GetFirstChildByName("y").Value())
				spriterObject.AddObjectPart(objectPart);
			Next
		Endif	
		
		'// Import the frames
		Local frames:StringMap<SpriterFrame> = New StringMap<SpriterFrame>
		For Local xmlFrame:XMLElement = Eachin rootElement.GetChildrenByName("frame")
			Local frame:SpriterFrame = New SpriterFrame
			frame.name = xmlFrame.GetFirstChildByName("name").Value
			For Local xmlSprite:XMLElement = Eachin xmlFrame.GetChildrenByName("sprite")
				Local sprite:SpriterSprite = New SpriterSprite
				sprite.objectPart = spriterObject.GetObjectParts().Get(xmlSprite.GetFirstChildByName("image").Value())
				If sprite.objectPart = Null Then ' create new object part
					Local objectPart:SpriterObjectPart = New SpriterObjectPart
					objectPart.textureName = xmlSprite.GetFirstChildByName("image").Value()
					textures.Load(spriterObject.basePath + objectPart.textureName)
					sprite.objectPart = objectPart
					spriterObject.AddObjectPart(objectPart)
				End
				sprite.colorBits = Float(xmlSprite.GetFirstChildByName("color").Value())
				sprite.opacity = Float(xmlSprite.GetFirstChildByName("opacity").Value())
				sprite.angle = Float(xmlSprite.GetFirstChildByName("angle").Value())
				If sprite.angle < 0
					sprite.angle += 360
				End
				sprite.x = Float(xmlSprite.GetFirstChildByName("x").Value())
				sprite.y = Float(xmlSprite.GetFirstChildByName("y").Value())
				sprite.width = Float(xmlSprite.GetFirstChildByName("width").Value())
				sprite.height = Float(xmlSprite.GetFirstChildByName("height").Value())

				frame.AddSprite(sprite)
			Next
			frames.Add(frame.name, frame)
		Next
		
		'// Import the animations
		For Local xmlAnim:XMLElement = Eachin rootElement.GetFirstChildByName("char").GetChildrenByName("anim")
			Local animation:SpriterAnimation = New SpriterAnimation
			animation.name = xmlAnim.GetFirstChildByName("name").Value()
			For Local xmlFrame:XMLElement = Eachin xmlAnim.GetChildrenByName("frame")
				Local animationFrame:SpriterAnimationFrame = New SpriterAnimationFrame
				animationFrame.duration = Float(xmlFrame.GetFirstChildByName("duration").Value())
				Local text:String = xmlFrame.GetFirstChildByName("name").Value()
				animationFrame.frame = frames.Get(text)
				animation.AddFrame(animationFrame)
			Next
			spriterObject.AddAnimation(animation)
		Next
		
		Return spriterObject
	End
End

Class SpriterDrawer
	Function Draw:Void(textureProvider:TextureProvider, spriterObject:SpriterObject, animationName:String, keyTime:Float, offsetX:Float, offsetY:Float)
		Local spriterAnimation:SpriterAnimation = spriterObject.GetAnimations().Get(animationName)
		If spriterAnimation = Null Then
			Error("The given animationname:" + animationName + " does not exist in the animation")
		End
		Local frames:ArrayList<SpriterAnimationFrame> = spriterAnimation.GetFrames()
		Local currentFrame:SpriterAnimationFrame = Null
		Local nextFrame:SpriterAnimationFrame = Null
		Local curTime:Float = 0
		Local tweenFactor:Float = 0
		For Local i:Int = 0 To frames.Size() - 1
			Local animationFrame:SpriterAnimationFrame = frames.Get(i)
			If curTime <= keyTime And curTime + animationFrame.duration > keyTime
				currentFrame = animationFrame
				If i < frames.Size() - 1
					nextFrame = frames.Get(i + 1)
				Else
					nextFrame = animationFrame
				End
				tweenFactor = (keyTime - curTime) / (animationFrame.duration)
				Exit
			End
			curTime += animationFrame.duration
		End
		If currentFrame= Null Then
			currentFrame = frames.Get(frames.Size() - 1)
			nextFrame = frames.Get(frames.Size() - 1)
		End
		
		'// iterate through all sprites And draw them
		Local sprites1:ArrayList<SpriterSprite> = currentFrame.frame.GetSprites()
		For Local i:Int = 0 To sprites1.Size() - 1
			Local sprite1:SpriterSprite = sprites1.Get(i)
			
			'// attention: Sprite uses an inverted y-axis: 0:0 is top left
			Local posX1:Float  = sprite1.x - sprite1.objectPart.originX + offsetX
			Local posY1:Float  = sprite1.y - sprite1.objectPart.originY + offsetY
			Local angle1:Float  = sprite1.angle
			
			Local posXTweened:Float
			Local posYTweened:Float
			Local angleTweened:Float
			'// perform tweening, If sprite occurs in next frame too
			Local sprite2:SpriterSprite = nextFrame.frame.GetSpriteByObjectPart(sprite1.objectPart)
			If sprite2 = Null '// no tweening possible
				posXTweened = posX1
				posYTweened = posY1
				angleTweened = angle1
			Else
				Local posX2:Float = sprite2.x - sprite2.objectPart.originX + offsetX
				Local posY2:Float = sprite2.y - sprite2.objectPart.originY + offsetY
				Local angle2:Float = sprite2.angle

				posXTweened = posX1 * (1 - tweenFactor) + posX2 * tweenFactor
				posYTweened = posY1 * (1 - tweenFactor) + posY2 * tweenFactor

				If (angle2 > angle1)
					If (angle2 - angle1 <= 180)
						angleTweened = angle1 * (1 - tweenFactor) + angle2 * tweenFactor
					Else
						angleTweened = (360 + angle1) * (1 - tweenFactor) + angle2 * tweenFactor
					End
				Else
					If (angle1 - angle2 <= 180)
						angleTweened = angle1 * (1 - tweenFactor) + angle2 * tweenFactor
					Else
						angleTweened = angle1 * (1 - tweenFactor) + (360 + angle2) * tweenFactor
					End
				End
			End
			
			'// Lets draw!
			Local img:Image = textureProvider.GetTexture(spriterObject.basePath + sprite1.objectPart.textureName)
			Local x# = posXTweened
			Local y# = posYTweened
			Local rot# = angleTweened
			Local scaleX# = 1
			Local scaleY# = 1
			DrawImage img, x, y, rot, scaleX, scaleY
		End
	End	
End

Class TextureProvider Extends StringMap<Image>

	Method Load:Image(name:String)
		Local storeKey:String = name.ToUpper()

		Local i:Image = New Image
		Local imgName:String = name
		imgName = imgName.Replace("\", "/")
		
		i = LoadImage(imgName )', 1, flags)
		If i = Null
			Error "Error loading image "+name
		End
		'Print "storing "+storeKey
		Self.Set(storeKey, i)
		Return i
	End
	
	Method DisplayAllStored:Void()
		' debug: print all keys in the map
		For Local key:String = Eachin Self.Keys()
			Print key + " is stored in the map."
		Next
	End
	
	Method GetTexture:Image(name:String)
		name = name.ToUpper()
	   	
		Local i:Image= Self.Get(name)
		If i = Null Then Error("Image '" + name + "' not found in the TextureProvider")
		Return i
	End	
End
