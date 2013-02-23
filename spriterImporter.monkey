Strict
Import mojo
Import diddy.xml

'-------------------------- Monkey Spriter Code --------------------------
Class MonkeySpriter
	Field textures:TextureProvider = New TextureProvider()
	Field folders:IntMap<SpriterFolder>
	Field entities:IntMap<SpriterEntity>
	Field mainPath:String
	Field animationName:String
	Field nextKeyTime:Int
	Field mainlineKeyId:Int
	Field timer:Timer
	Field scaleX:Float = 1
	Field scaleY:Float = 1
	Field x:Float, y:Float
	Const LOOPING_FALSE:Int = 0
	Const LOOPING_TRUE:Int = 1
	Const LOOPING_PING_PONG:Int = 2
	
	Method New()
		Self.folders = New IntMap<SpriterFolder>
		Self.entities = New IntMap<SpriterEntity>
		mainlineKeyId = 0
		timer = New Timer
	End
	
	Method Copy:MonkeySpriter()
		Local ms:MonkeySpriter = New MonkeySpriter
		ms.textures = Self.textures
		ms.folders  = Self.folders
		ms.entities = Self.entities
		ms.mainPath = Self.mainPath
		ms.animationName = Self.animationName
		ms.nextKeyTime   = Self.nextKeyTime
		ms.mainlineKeyId = Self.mainlineKeyId
		ms.timer = New Timer
		ms.scaleX = Self.scaleX
		ms.scaleY = Self.scaleY
		ms.x = Self.x
		ms.y = Self.y
		Return ms
	End Method
	
	Method Update:Void(animationName:String, looping:Int = LOOPING_TRUE, timeElapsed:Int)
		Self.animationName = animationName
		If Not timer.stopped
			timer.Update(timeElapsed)
			Local animation:SpriterAnimation
			Try
				animation = entities.Get(0).animations.Get(animationName)
				If animation = Null Then Throw New Throwable
			Catch ex:Throwable
        		Print "Animation is null! Can not find animation " + animationName
			End
			
			If looping <> "" Then
				animation.looping = looping
			End
			Local mainline:SpriterMainline = animation.mainline
			If timer.GetTime() >= animation.length
				If animation.looping = LOOPING_TRUE
					timer.Reset()
				Else If animation.looping = LOOPING_PING_PONG
					timer.direction = timer.DOWN
				Else If animation.looping = LOOPING_FALSE
					timer.Stop()
				End
			End
			If animation.looping = LOOPING_PING_PONG And timer.GetTime() <= 0
				timer.direction = timer.UP
				timer.Reset()
			End
		End		
	End
	
	Method Draw:Void(tween:Bool = False)
		Local anim:SpriterAnimation = entities.Get(0).animations.Get(animationName)
		If anim = Null Return
		Local mainline:SpriterMainline = anim.mainline
		
		Local time:Float = timer.GetTime()
		mainlineKeyId = mainline.GetKeyViaTime(time).id
		Local mainlineKey:SpriterKey = mainline.keys.Get(mainlineKeyId)

		For Local i:Int = Eachin mainlineKey.objectRefs.Keys()
			Local objRef:SpriterObjectRef = mainlineKey.objectRefs.Get(i)
			Local timeline:SpriterTimeline = anim.timelines.Get(objRef.timeline)
			Local timelineKey:SpriterKey = timeline.GetKeyViaTime(time)
			Local nextTimelineKey:SpriterKey = timeline.keys.Get(objRef.key + 1)
			Local nextKeyTime:Int
			
			If nextTimelineKey = Null Then
				If anim.looping = LOOPING_TRUE
					nextTimelineKey = timeline.keys.Get(0)
					nextKeyTime = anim.length
					' next timeline might not start at the beginning of the animation
					If nextTimelineKey.time > 0 Then
						nextKeyTime += nextTimelineKey.time
					End
				Else If anim.looping = LOOPING_PING_PONG
					If timer.direction = timer.UP
						nextKeyTime = anim.length
					Else
						nextKeyTime = 0
					End
					nextTimelineKey = timelineKey
				Else If anim.looping = LOOPING_FALSE
					nextTimelineKey = timelineKey
					nextKeyTime = anim.length	
				End
			Else
				nextKeyTime = nextTimelineKey.time
			End
			
			Local nextO:SpriterObject = nextTimelineKey.objects.Last()

			For Local o:SpriterObject = Eachin timelineKey.objects
				Local folder:SpriterFolder = Self.folders.Get(o.folder)
				Local file:SpriterFile = folder.files.Get(o.file)
				Local texture:Image = textures.GetTexture(Self.mainPath + "/" + file.name.ToUpper())

				Local nextFolder:SpriterFolder = Self.folders.Get(nextO.folder)
				Local nextFile:SpriterFile = nextFolder.files.Get(nextO.file)
				Local nextTexture:Image = textures.GetTexture(Self.mainPath + "/" + nextFile.name.ToUpper())
			
				Local currentAngle:Float = o.angle
				Local nextAngle:Float = nextO.angle

				'XOR
				If (scaleX < 0) <> (scaleY < 0) Then
					currentAngle = -currentAngle
					nextAngle = -nextAngle
				End
				
				If tween
					Local x1# = o.x
					Local x2# = nextO.x
					Local y1# = o.y
					Local y2# = nextO.y
					
					Local tweenedPivotX:Float = LinearInterpolation(o.pivotX, nextO.pivotX, timelineKey.time, nextKeyTime, time)
					Local tweenedPivotY:Float = LinearInterpolation(o.pivotY, nextO.pivotY, timelineKey.time, nextKeyTime, time)
					
					Local tweenedX:Float = LinearInterpolation(x1, x2, timelineKey.time, nextKeyTime, time)
					Local tweenedY:Float = LinearInterpolation(y1, y2, timelineKey.time, nextKeyTime, time)
					Local tweenedAngle:Float = AngleLinearInterpolation(currentAngle, nextAngle, timelineKey.time, nextKeyTime, time)
					Local tweenedScaleX:Float = LinearInterpolation(o.scaleX, nextO.scaleX, timelineKey.time, nextKeyTime, time)
					Local tweenedScaleY:Float = LinearInterpolation(o.scaleY, nextO.scaleY, timelineKey.time, nextKeyTime, time)
					Local tweenedAlpha:Float = LinearInterpolation(o.alpha, nextO.alpha, timelineKey.time, nextKeyTime, time)

					texture.SetHandle(tweenedPivotX * texture.Width(),  nextTexture.Height() + (-tweenedPivotY * nextTexture.Height()))
					
					SetAlpha(tweenedAlpha)
					DrawImage(texture, tweenedX * scaleX + x, -tweenedY * scaleY + y, tweenedAngle, tweenedScaleX * scaleX, tweenedScaleY * scaleY, 0)
				Else
					texture.SetHandle(o.pivotX * texture.Width(),  nextTexture.Height() + (-o.pivotY * nextTexture.Height()))
					SetAlpha(o.alpha)
					DrawImage(texture, o.x * scaleX + x, -o.y * scaleY + y, currentAngle, o.scaleX * scaleX, o.scaleY * scaleY, 0)
				End
			Next		
			SetAlpha(1)
		Next
	End
	
	Method LinearInterpolation:Float(a:Float, b:Float, timeA:Float, timeB:Float, currentTime:Float)
		Return a + ((b - a) * ((currentTime - timeA) / (timeB - timeA)))
	End
	
	Method AngleLinearInterpolation:Float(a:Float, b:Float, timeA:Float, timeB:Float, currentTime:Float)
		return a + (AngleDifference(b, a) * ((currentTime - timeA) / (timeB - timeA)))
	End
	
	Method AngleDifference:Float(a:Float, b:Float)
		Return ((((a - b) Mod 360) + 540) Mod 360) - 180
	End
	
	Method SetScale:Void(scaleX:Float, scaleY:Float)
		Self.scaleX = scaleX
		Self.scaleY = scaleY
	End
End

Class SpriterFolder
	Field files:IntMap<SpriterFile>
	Field id:Int
	Field name:String
	
	Method New()
		Self.files = New IntMap<SpriterFile>
	End
End

Class SpriterFile
	Field id:Int
	Field name:String
	Field width:Int
	Field height:Int
End

Class SpriterEntity
	Field id:Int
	Field name:String
	Field animations:StringMap<SpriterAnimation>
	
	Method New()
		Self.animations = New StringMap<SpriterAnimation>
	End
End

Class SpriterAnimation
	Field id:Int
	Field name:String
	Field length:Int
	Field looping:Int
	Field mainline:SpriterMainline
	Field timelines:IntMap<SpriterTimeline>
	Field maxKey:Int
	
	Method New()
		Self.mainline = New SpriterMainline
		Self.timelines = New IntMap<SpriterTimeline>
	End
End

Class SpriterMainline
	Field keys:IntMap<SpriterKey>
	Field keyId:Int = 0
	Field delay:Float = 0
	Field maxDelay:Int = 5
	Field speed:Float = 1.5
	Field maxKey:Int
		
	Method New()
		Self.keys = New IntMap<SpriterKey>
	End
		
	Method GetKey:SpriterKey(timer:Timer)
		Local rv:SpriterKey = Self.keys.Get(0)
		For Local i:Int = Eachin Self.keys.Keys()
			Local key:SpriterKey = Self.keys.Get(i)
			If key.time > timer.GetTime()
				Return rv
			End
			rv = key
		Next
		Return rv
	End
	
	Method GetKeyViaTime:SpriterKey(time:Float)
		Local rv:SpriterKey = Self.keys.Get(0)
		For Local i:Int = Eachin Self.keys.Keys()
			Local key:SpriterKey = Self.keys.Get(i)
			If key.time > time
				Return rv
			End
			rv = key
		Next
		Return rv
	End

End

Class SpriterKey
	Field id:Int
	Field time:Int
	Field spin:Int
	Field objectRefs:IntMap<SpriterObjectRef>
	Field objects:List<SpriterObject>
	Field boneRefs:IntMap<SpriterBoneRef>
	Field bones:List<SpriterBone>
	
	Method New()
		Self.objectRefs = New IntMap<SpriterObjectRef>
		Self.objects = New List<SpriterObject>
		Self.boneRefs = New IntMap<SpriterBoneRef>
		Self.bones = New List<SpriterBone>
	End
End

Class SpriterBoneRef
	Field id:Int
	Field timeline:Int
	Field parent:Int
	Field key:Int
End

Class SpriterObjectRef
	Field id:Int
	Field timeline:Int
	Field key:Int
	Field zIndex:Int
	Field parent:Int
End

Class SpriterTimeline
	Field id:Int
	Field keys:IntMap<SpriterKey>
	Field keyId:Int = 0
	Field delay:Float = 0
	Field maxDelay:Int = 5
	Field speed:Float = 1.5
	Field maxKey:Int
	Field name:String
	
	Method New()
		Self.keys = New IntMap<SpriterKey>
	End
	
	Method GetKey:SpriterKey(timer:Timer)
		Local rv:SpriterKey = Self.keys.Get(0)
		For Local i:Int = Eachin Self.keys.Keys()
			Local key:SpriterKey = Self.keys.Get(i)
			If key.time > timer.GetTime()
				Return rv
			End
			rv = key
		Next
		Return rv
	End
	
	Method GetKeyViaTime:SpriterKey(time:Float)
		Local rv:SpriterKey = Self.keys.Get(0)
		For Local i:Int = Eachin Self.keys.Keys()
			Local key:SpriterKey = Self.keys.Get(i)
			If key.time > time
				Return rv
			End
			rv = key
		Next
		Return rv
	End

End

Class SpriterObject
	Field folder:Int
	Field file:Int
	Field x:Float
	Field y:Float
	Field pivotX:Float
	Field pivotY:Float
	Field angle:Float
	Field scaleX:Float
	Field scaleY:Float
	Field alpha:Float
End

Class SpriterBone
	Field x:Float
	Field y:Float
	Field angle:Float
	Field scaleX:Float
	Field scaleY:Float
End

Class SpriterImporter
	Function ImportFile:MonkeySpriter(parent:String, file:String, atlasPath:String = "", debug:Bool = False)
		If debug Then Print "Importing " + parent + "/" + file

		Local str:String = LoadString(parent + "/" + file)
		If str = "" Then Error "Error loading file..." + parent + "/" + file
		
		Local xmlReader:XMLParser = New XMLParser		
		Local doc:XMLDocument = xmlReader.ParseString(str)
		Local rootElement:XMLElement = doc.Root

		Local smo:MonkeySpriter = New MonkeySpriter()
		smo.mainPath = parent
		For Local folderElement:XMLElement = Eachin rootElement.GetChildrenByName("folder")
			Local folder:SpriterFolder = New SpriterFolder()
			folder.id = Int(folderElement.GetAttribute("id"))
			folder.name = folderElement.GetAttribute("name")
			If debug Print "folder = " + folder.id + " " + folder.name
			
			For Local fileElement:XMLElement = Eachin folderElement.GetChildrenByName("file")
				Local file:SpriterFile = New SpriterFile()
				file.id = Int(fileElement.GetAttribute("id"))
				file.name = fileElement.GetAttribute("name")
				file.width = Int(fileElement.GetAttribute("width"))
				file.height = Int(fileElement.GetAttribute("height"))
				
				If debug Print "file = " + file.id + " " + file.name
				If atlasPath
					smo.textures.LoadAtlas(parent, atlasPath)
				Else
					smo.textures.Load(parent + "/" + file.name)
				End
				
				folder.files.Add(file.id, file)
			Next
			smo.folders.Add(folder.id, folder)
		Next
		
		For Local entityElement:XMLElement = Eachin rootElement.GetChildrenByName("entity")
			Local entity:SpriterEntity = New SpriterEntity()
			Local id:String = entityElement.GetAttribute("id")
			Local name:String = entityElement.GetAttribute("name")
			
			If debug Print "entity = " + id + " " + name
			For Local animationElement:XMLElement = Eachin entityElement.GetChildrenByName("animation")
				Local animation:SpriterAnimation = New SpriterAnimation()
				animation.id  = Int(animationElement.GetAttribute("id"))
				animation.name = animationElement.GetAttribute("name")
				animation.length = Int(animationElement.GetAttribute("length"))
				Local looping:String = animationElement.GetAttribute("looping", MonkeySpriter.LOOPING_FALSE)
				Select looping
					Case "true"
						animation.looping = MonkeySpriter.LOOPING_TRUE
					Case "false"
						animation.looping = MonkeySpriter.LOOPING_FALSE
					Case "ping_pong"
						animation.looping = MonkeySpriter.LOOPING_PING_PONG
				End

				If debug Print "animation = " + animation.id + " " + animation.name
				
				' Should only be one mainline element
				For Local mainlineElement:XMLElement = Eachin animationElement.GetChildrenByName("mainline")
					For Local keyElement:XMLElement = Eachin mainlineElement.GetChildrenByName("key")
						Local skey:SpriterKey = New SpriterKey()
						skey.id = Int(keyElement.GetAttribute("id"))
						skey.time= Int(keyElement.GetAttribute("time", "0"))
						If debug Print "key = " + skey.id + " " + skey.time

						For Local boneRefElement:XMLElement = Eachin keyElement.GetChildrenByName("bone_ref")
							Local boneRef:SpriterBoneRef = New SpriterBoneRef
							boneRef.id = Int(boneRefElement.GetAttribute("id"))
							boneRef.parent = Int(boneRefElement.GetAttribute("parent", "-1"))
							boneRef.timeline = Int(boneRefElement.GetAttribute("timeline"))
							boneRef.key = Int(boneRefElement.GetAttribute("key"))
							If debug Then Print "bone_ref = " + boneRef.id + " " + boneRef.timeline
							skey.boneRefs.Add(boneRef.id, boneRef)
						Next

						For Local objectRefElement:XMLElement = Eachin keyElement.GetChildrenByName("object_ref")
							Local objectRef:SpriterObjectRef = New SpriterObjectRef
							objectRef.id = Int(objectRefElement.GetAttribute("id"))
							objectRef.timeline = Int(objectRefElement.GetAttribute("timeline"))
							objectRef.key = Int(objectRefElement.GetAttribute("key"))
							objectRef.zIndex = Int(objectRefElement.GetAttribute("z_index"))
							objectRef.parent = Int(objectRefElement.GetAttribute("parent", "-1"))
							If debug Print "object_ref = " + objectRef.id + " " + objectRef.timeline + " " + objectRef.parent
							
							skey.objectRefs.Add(objectRef.id, objectRef)
						Next
						animation.mainline.keys.Add(skey.id, skey)
						animation.maxKey = skey.id
					Next	
				Next
				
				For Local timelineElement:XMLElement = Eachin animationElement.GetChildrenByName("timeline")
					Local timeline:SpriterTimeline = New SpriterTimeline()
					timeline.id = Int(timelineElement.GetAttribute("id"))
					timeline.name = timelineElement.GetAttribute("id", "")
					If debug Print "timeline = " + timeline.id + " " + timeline.name
					
					For Local keyElement:XMLElement = Eachin timelineElement.GetChildrenByName("key")
						Local key:SpriterKey = New SpriterKey()
						key.id = Int(keyElement.GetAttribute("id"))
						key.time = Int(keyElement.GetAttribute("time", "0"))
						key.spin = Int(keyElement.GetAttribute("spin", "1"))
						If debug Print "key = " + key.id + " " + key.time + " " + key.spin
						
						For Local boneElement:XMLElement = Eachin keyElement.GetChildrenByName("bone")
							Local b:SpriterBone = New SpriterBone()
							b.x = Float(boneElement.GetAttribute("x", "0"))
							b.y = Float(boneElement.GetAttribute("y", "0"))
							b.angle = Float(boneElement.GetAttribute("angle", "0"))
							b.scaleX = Float(boneElement.GetAttribute("scale_x", "1"))
							b.scaleY = Float(boneElement.GetAttribute("scale_y", "1"))
							
							If debug Print "bone = " + b.x + " " + b.y + " " + b.angle
							
							key.bones.AddLast(b)
						Next
						
						For Local objectElement:XMLElement = Eachin keyElement.GetChildrenByName("object")						
							Local o:SpriterObject = New SpriterObject()
							o.folder = Int(objectElement.GetAttribute("folder"))
							o.file = Int(objectElement.GetAttribute("file"))
							o.x = Float(objectElement.GetAttribute("x", "0"))
							o.y = Float(objectElement.GetAttribute("y", "0"))
							o.pivotX = Float(objectElement.GetAttribute("pivot_x", "0"))
							o.pivotY = Float(objectElement.GetAttribute("pivot_y", "1"))
							o.angle = Float(objectElement.GetAttribute("angle", "0"))
							o.scaleX = Float(objectElement.GetAttribute("scale_x", "1"))
							o.scaleY = Float(objectElement.GetAttribute("scale_y", "1"))
							o.alpha = Float(objectElement.GetAttribute("a", "1"))
							
							If debug Print "object = " + o.folder + " " + o.file + " " + o.angle
														
							key.objects.AddLast(o)
						Next
						timeline.keys.Add(key.id, key)
					Next
					animation.timelines.Add(timeline.id, timeline)
				Next
				entity.animations.Add(animation.name, animation)
			Next
			smo.entities.Add(entity.id, entity)
		Next
		Return smo
	End
End

Class TextureProvider Extends StringMap<Image>
	Field path:String = "graphics/"
	
	Method Load:Image(name:String)
		Local storeKey:String = name.ToUpper()

		Local i:Image = New Image
		Local imgName:String = name

		i = LoadImage(imgName )', 1, flags)
		If i = Null
			Error "Error loading image "+name
		End
		'Print "storing "+storeKey
		Self.Set(storeKey, i)
		Return i
	End
	
	Method LoadAtlas:Void(parent:String, fileName:String)
		Local str:String = LoadString(fileName)
		If str = "" Then Error "Error loading atlas..." + fileName

		' parse the xml
		Local parser:XMLParser = New XMLParser
		Local doc:XMLDocument = parser.ParseString(str)
		Local rootElement:XMLElement = doc.Root
		Local spriteFileName:String = rootElement.GetAttribute("imagePath")
		
		Local pointer:Image = LoadImage(path + spriteFileName)
		If Not pointer Then Error "Error loading bitmap atlas "+ path + spriteFileName
		
		For Local node:XMLElement = Eachin rootElement.GetChildrenByName("SubTexture")
			Local x:Int = Int(node.GetAttribute("x").Trim())
			Local y:Int = Int(node.GetAttribute("y").Trim())
			Local width:Int = Int(node.GetAttribute("width").Trim())
			Local height:Int = Int(node.GetAttribute("height").Trim())
			Local name:String = node.GetAttribute("name").Trim()

			Local i:Image = New Image
			i = pointer.GrabImage(x, y, width, height)
			Self.Set(parent.ToUpper() + "/" + name.ToUpper() + ".PNG", i)
		Next
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

Class Timer
	Field stopped:Bool
	Field rate:Float
	Const UP:Int = 1
	Const DOWN:Int = -1
	Field direction:Int
	Field count:Float
	
	Method New()
		stopped = True
		rate = 1
		direction = UP
	End
	
	Method Start:Void()
		Reset()
		Resume()
		rate = 1
	End
	
	Method Stop:Void()
		If Not stopped
			stopped = True
		End
	End
	
	Method Resume:Void()
		If stopped
			stopped = False
		End
	End
	
	Method Reset:Void()
		count = 0
		direction = UP
	End
	
	Method GetTime:Float()
		Return count / rate
	End

	Method Update:Void(timeElapsed:Int)
		If direction = UP
			count+=timeElapsed
		Else
			count-=timeElapsed
		End
	End
End