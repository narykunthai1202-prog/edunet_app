# ZEGO UIKit Flutter Services API

- [ZEGO UIKit Flutter Services API](#zego-uikit-flutter-services-api)
  - [Services Overview](#services-overview)
  - [AudioVideoService](#audiovideoservice)
    - [turnCameraOn](#turncameraon)
    - [turnMicrophoneOn](#turnmicrophoneon)
    - [useFrontFacingCamera](#usefrontfacingcamera)
    - [startPlayingStream](#startplayingstream)
    - [stopPlayingStream](#stopplayingstream)
    - [startPlayAllAudioVideo](#startplayallaudiovideo)
    - [stopPlayAllAudioVideo](#stopplayallaudiovideo)
    - [startPlayAllAudio](#startplayallaudio)
    - [stopPlayAllAudio](#stopplayallaudio)
    - [muteUserAudioVideo](#muteuseraudiovideo)
    - [muteUserAudio](#muteuseraudio)
    - [muteUserVideo](#muteuservideo)
    - [setAudioOutputToSpeaker](#setaudiooutputtospeaker)
    - [setAudioConfig](#setaudioconfig)
    - [enableAEC](#enableaec)
    - [enableHeadphoneAEC](#enableheadphoneaec)
    - [setAECMode](#setaecmode)
    - [enableAGC](#enableagc)
    - [enableANS](#enableans)
    - [enableTransientANS](#enabletransientans)
    - [setANSMode](#setansmode)
    - [setVideoConfig](#setvideoconfig)
    - [enableTrafficControl](#enabletrafficcontrol)
    - [enableVideoMirroring](#enablevideomirroring)
    - [setAudioVideoResourceMode](#setaudiovideoresourcemode)
    - [enableSyncDeviceStatusBySEI](#enablesyncdevicestatusbysei)
    - [sendCustomSEI](#sendcustomsei)
    - [getAudioVideoViewNotifier](#getaudiovideoviewnotifier)
    - [getAudioVideoViewIDNotifier](#getaudiovideoviewidnotifier)
    - [getAudioVideoQualityNotifier](#getaudiovideoqualitynotifier)
    - [getAudioVideoCapturedAudioFirstFrameNotifier](#getaudiovideocapturedaudiofirstframenotifier)
    - [getAudioVideoCapturedVideoFirstFrameNotifier](#getaudiovideocapturedvideofirstframenotifier)
    - [getAudioVideoSendAudioFirstFrameNotifier](#getaudiovideosendaudiofirstframenotifier)
    - [getAudioVideoSendVideoFirstFrameNotifier](#getaudiovideosendvideofirstframenotifier)
    - [getCameraStateNotifier](#getcamerastatenotifier)
    - [getUseFrontFacingCameraStateNotifier](#getusefrontfacingcamerastatenotifier)
    - [getMicrophoneStateNotifier](#getmicrophonestatenotifier)
    - [getAudioOutputDeviceNotifier](#getaudiooutputdevicenotifier)
    - [getScreenSharingStateNotifier](#getscreensharingstatenotifier)
    - [getSoundLevelStream](#getsoundlevelstream)
    - [getAudioVideoListStream](#getaudiovideoliststream)
    - [getAudioVideoList](#getaudiovideolist)
    - [getScreenSharingListStream](#getscreensharingliststream)
    - [getScreenSharingList](#getscreensharinglist)
    - [getMediaListStream](#getmedialiststream)
    - [getMediaList](#getmedialist)
    - [startSharingScreen](#startsharingscreen)
    - [stopSharingScreen](#stopsharingscreen)
    - [getVideoSizeNotifier](#getvideosizenotifier)
    - [updateTextureRendererOrientation](#updatetexturerendererorientation)
    - [updateAppOrientation](#updateapporientation)
    - [updateVideoViewMode](#updatevideoviewmode)
    - [getReceiveSEIStream](#getreceiveseistream)
    - [getReceiveCustomSEIStream](#getreceivecustomseistream)
    - [getGeneratedStreamID](#getgeneratedstreamid)
  - [ChannelService](#channelservice)
    - [backToDesktop](#backtodesktop)
    - [isLockScreen](#islockscreen)
    - [checkAppRunning](#checkapprunning)
    - [activeAppToForeground](#activeapptoforeground)
    - [stopIOSPIP](#stopiospip)
    - [isIOSInPIP](#isiosinpip)
    - [enableIOSPIP](#enableiospip)
    - [updateIOSPIPSource](#updateiospipsource)
    - [enableIOSPIPAuto](#enableiospipauto)
    - [enableHardwareDecoder](#enablehardwaredecoder)
    - [enableCustomVideoRender](#enablecustomvideorender)
    - [onWillPop](#onwillpop)
    - [openAppSettings](#openappsettings)
    - [requestDismissKeyguard](#requestdismisskeyguard)
    - [startPlayingStreamInPIP](#startplayingstreaminpip)
    - [stopPlayingStreamInPIP](#stopplayingstreaminpip)
  - [CustomCommandService](#customcommandservice)
    - [sendCustomCommand](#sendcustomcommand)
    - [getInRoomCommandReceivedStream](#getinroomcommandreceivedstream)
  - [DeviceService](#deviceservice)
    - [getDeviceInfo](#getdeviceinfo)
    - [getSystemInfo](#getsysteminfo)
    - [getCameraList](#getcameralist)
    - [getMicrophoneList](#getmicrophonelist)
    - [getTurnOnYourCameraRequestStream](#getturnonyourcamerarequeststream)
    - [getTurnOnYourMicrophoneRequestStream](#getturnonyourmicrophonerequeststream)
    - [enableCustomVideoProcessing](#enablecustomvideoprocessing)
    - [getMobileSystemVersionX](#getmobilesystemversionx)
    - [getMobileSystemVersion](#getmobilesystemversion)
    - [setAudioDeviceMode](#setaudiodevicemode)
  - [EffectService](#effectservice)
    - [setBeautyEffect](#setbeautyeffect)
    - [setVirtualBackground](#setvirtualbackground)
    - [enableBeauty](#enablebeauty)
    - [startEffectsEnv](#starteffectsenv)
    - [stopEffectsEnv](#stopeffectsenv)
    - [setBeautifyValue](#setbeautifyvalue)
    - [getBeautyValue](#getbeautyvalue)
    - [setVoiceChangerType](#setvoicechangertype)
    - [setReverbType](#setreverbtype)
    - [resetSoundEffect](#resetsoundeffect)
    - [resetBeautyEffect](#resetbeautyeffect)
  - [EventService](#eventservice)
    - [listen](#listen)
    - [unlisten](#unlisten)
    - [enableEventUninitOnRoomLeaved](#enableeventuninitonroomleaved)
    - [registerExpressEvent](#registerexpressevent)
    - [unregisterExpressEvent](#unregisterexpressevent)
  - [LoggerService](#loggerservice)
    - [logInfo](#loginfo)
    - [logWarning](#logwarning)
    - [logError](#logerror)
    - [initLog](#initlog)
    - [clearLogs](#clearlogs)
    - [exportLogs](#exportlogs)
    - [logWarn](#logwarn)
    - [logErrorTrace](#logerrortrace)
  - [MediaService](#mediaservice)
    - [startMediaPlayer](#startmediaplayer)
    - [pauseMediaPlayer](#pausemediaplayer)
    - [resumeMediaPlayer](#resumemediaplayer)
    - [stopMediaPlayer](#stopmediaplayer)
    - [registerMediaEvent](#registermediaevent)
    - [unregisterMediaEvent](#unregistermediaevent)
    - [playMedia](#playmedia)
    - [startMedia](#startmedia)
    - [stopMedia](#stopmedia)
    - [pauseMedia](#pausemedia)
    - [resumeMedia](#resumemedia)
    - [destroyMedia](#destroymedia)
    - [seekTo](#seekto)
    - [setMediaVolume](#setmediavolume)
    - [getMediaVolume](#getmediavolume)
    - [muteMediaLocal](#mutemedialocal)
    - [getMediaMuteNotifier](#getmediamutenotifier)
    - [getMediaVolumeNotifier](#getmediavolumenotifier)
    - [getMediaTotalDuration](#getmediatotalduration)
    - [getMediaCurrentProgress](#getmediacurrentprogress)
    - [getMediaCurrentProgressNotifier](#getmediacurrentprogressnotifier)
    - [getMediaType](#getmediatype)
    - [getMediaTypeNotifier](#getmediatypenotifier)
    - [getMediaPlayStateNotifier](#getmediaplaystatenotifier)
    - [pickPureAudioMediaFile](#pickpureaudiomediafile)
    - [pickVideoMediaFile](#pickvideomediafile)
    - [pickMediaFile](#pickmediafile)
    - [getMediaInfo](#getmediainfo)
  - [MessageService](#messageservice)
    - [sendBroadcastMessage](#sendbroadcastmessage)
    - [sendBarrageMessage](#sendbarragemessage)
    - [sendCustomMessage](#sendcustommessage)
    - [sendInRoomMessage](#sendinroommessage)
    - [resendInRoomMessage](#resendinroommessage)
    - [getInRoomMessages](#getinroommessages)
    - [getInRoomMessageListStream](#getinroommessageliststream)
    - [getInRoomMessageStream](#getinroommessagestream)
    - [getInRoomLocalMessageStream](#getinroomlocalmessagestream)
    - [clearMessage](#clearmessage)
  - [MixerService](#mixerservice)
    - [startMixerTask](#startmixertask)
    - [stopMixerTask](#stopmixertask)
    - [updateMixerLayout](#updatemixerlayout)
    - [startPlayAnotherRoomAudioVideo](#startplayanotherroomaudiovideo)
    - [stopPlayAnotherRoomAudioVideo](#stopplayanotherroomaudiovideo)
    - [startPlayMixAudioVideo](#startplaymixaudiovideo)
    - [stopPlayMixAudioVideo](#stopplaymixaudiovideo)
    - [getMixAudioVideoViewNotifier](#getmixaudiovideoviewnotifier)
    - [getMixAudioVideoCameraStateNotifier](#getmixaudiovideocamerastatenotifier)
    - [getMixAudioVideoMicrophoneStateNotifier](#getmixaudiovideomicrophonestatenotifier)
    - [getMixAudioVideoLoadedNotifier](#getmixaudiovideoloadednotifier)
    - [getMixedSoundLevelsStream](#getmixedsoundlevelsstream)
    - [getMixedSoundLevelStream](#getmixedsoundlevelstream)
    - [getUserInMixerStream](#getuserinmixerstream)
    - [getMixerStreamUsers](#getmixerstreamusers)
    - [getMixerUserListStream](#getmixeruserliststream)
  - [PluginService](#pluginservice)
    - [registerPlugin](#registerplugin)
    - [unregisterPlugin](#unregisterplugin)
    - [pluginsInstallNotifier](#pluginsinstallnotifier)
    - [installPlugins](#installplugins)
    - [uninstallPlugins](#uninstallplugins)
    - [adapterService](#adapterservice)
    - [getPlugin](#getplugin)
    - [getSignalingPlugin](#getsignalingplugin)
    - [getBeautyPlugin](#getbeautyplugin)
  - [RoomService](#roomservice)
    - [joinRoom](#joinroom)
    - [leaveRoom](#leaveroom)
    - [updateRoomProperties](#updateroomproperties)
    - [isRoomLogin](#isroomlogin)
    - [renewRoomToken](#renewroomtoken)
    - [getRoom](#getroom)
    - [getRoomStateStream](#getroomstatestream)
    - [setRoomProperty](#setroomproperty)
    - [getRoomProperties](#getroomproperties)
    - [getRoomPropertyStream](#getroompropertystream)
    - [getRoomTokenExpiredStream](#getroomtokenexpiredstream)
    - [getRoomPropertiesStream](#getroompropertiesstream)
    - [getNetworkStateNotifier](#getnetworkstatenotifier)
    - [getNetworkState](#getnetworkstate)
    - [getNetworkModeStream](#getnetworkmodestream)
  - [UIKitService](#uikitservice)
    - [init](#init)
    - [uninit](#uninit)
    - [getVersion](#getversion)
  - [UserService](#userservice)
    - [getLocalUser](#getlocaluser)
    - [getAllUsers](#getallusers)
    - [getUserByID](#getuserbyid)
    - [login](#login)
    - [logout](#logout)
    - [getRemoteUsers](#getremoteusers)
    - [getLeaveUsers](#getleaveusers)
    - [clearLeaveUsers](#clearleaveusers)
    - [getLeaveUsersCache](#getleaveuserscache)
    - [clearLeaveUsersCache](#clearleaveuserscache)
    - [getDeletedStreamUserIDs](#getdeletedstreamuserids)
    - [clearDeletedStreamUserIDs](#cleardeletedstreamuserids)
    - [getUser](#getuser)
    - [getInRoomUserAttributesNotifier](#getinroomuserattributesnotifier)
    - [getUserListStream](#getuserliststream)
    - [getUserJoinStream](#getuserjoinstream)
    - [getUserLeaveStream](#getuserleavestream)
    - [removeUserFromRoom](#removeuserfromroom)
    - [getMeRemovedFromRoomStream](#getmeremovedfromroomstream)

---

## Services Overview

ZEGO UIKit Flutter SDK provides a series of service modules for managing and controlling various aspects of real-time audio and video communication, including audio/video control, room management, user management, message sending, device control, and other functions.

## AudioVideoService

Handles audio and video-related functions, such as camera and microphone control, and audio/video stream playback.

### turnCameraOn

> Turn on or off the camera.
>
> - function prototype:
>
> ```dart
> Future<void> turnCameraOn(bool isOn, {String? userID}) async
> ```
>
> - parameters:
>   - `isOn`: Whether to turn on the camera.
>   - `userID`: The ID of the user whose camera to control. If empty, controls the local user's camera.

### turnMicrophoneOn

> Turn on or off the microphone.
>
> - function prototype:
>
> ```dart
> Future<void> turnMicrophoneOn(bool isOn, {String? userID}) async
> ```
>
> - parameters:
>   - `isOn`: Whether to turn on the microphone.
>   - `userID`: The ID of the user whose microphone to control. If empty, controls the local user's microphone.

### useFrontFacingCamera

> Switch between front and back cameras.
>
> - function prototype:
>
> ```dart
> Future<void> useFrontFacingCamera(bool isFrontFacing) async
> ```
>
> - parameters:
>   - `isFrontFacing`: Whether to use the front camera.

### startPlayingStream

> Start playing a user's audio/video stream.
>
> - function prototype:
>
> ```dart
> Future<void> startPlayingStream(String userID) async
> ```
>
> - parameters:
>   - `userID`: The ID of the user whose stream to play.

### stopPlayingStream

> Stop playing a user's audio/video stream.
>
> - function prototype:
>
> ```dart
> Future<void> stopPlayingStream(String userID) async
> ```
>
> - parameters:
>   - `userID`: The ID of the user whose stream to stop playing.

### startPlayAllAudioVideo

> Start playing all audio and video streams in the room.
>
> - function prototype:
>
> ```dart
> Future<void> startPlayAllAudioVideo() async
> ```

### stopPlayAllAudioVideo

> Stop playing all audio and video streams in the room.
>
> - function prototype:
>
> ```dart
> Future<void> stopPlayAllAudioVideo() async
> ```

### startPlayAllAudio

> Start playing all audio streams in the room.
>
> - function prototype:
>
> ```dart
> Future<void> startPlayAllAudio() async
> ```

### stopPlayAllAudio

> Stop playing all audio streams in the room.
>
> - function prototype:
>
> ```dart
> Future<void> stopPlayAllAudio() async
> ```

### muteUserAudioVideo

> Mute or unmute a user's audio and video.
>
> - function prototype:
>
> ```dart
> Future<bool> muteUserAudioVideo(String userID, bool mute) async
> ```
>
> - parameters:
>   - `userID`: The ID of the user whose audio and video to mute.
>   - `mute`: Whether to mute the audio and video.
>
> - returns:
>   - `bool`: Whether the operation was successful.

### muteUserAudio

> Mute or unmute a user's audio.
>
> - function prototype:
>
> ```dart
> Future<bool> muteUserAudio(String userID, bool mute) async
> ```
>
> - parameters:
>   - `userID`: The ID of the user whose audio to mute.
>   - `mute`: Whether to mute the audio.
>
> - returns:
>   - `bool`: Whether the operation was successful.

### muteUserVideo

> Mute or unmute a user's video.
>
> - function prototype:
>
> ```dart
> Future<bool> muteUserVideo(String userID, bool mute) async
> ```
>
> - parameters:
>   - `userID`: The ID of the user whose video to mute.
>   - `mute`: Whether to mute the video.
>
> - returns:
>   - `bool`: Whether the operation was successful.

### setAudioOutputToSpeaker

> Set the audio output to speaker or earphone.
>
> - function prototype:
>
> ```dart
> void setAudioOutputToSpeaker(bool isSpeaker)
> ```
>
> - parameters:
>   - `isSpeaker`: Whether to output audio to the speaker.

### setAudioConfig

> Set the audio configuration.
>
> - function prototype:
>
> ```dart
> Future<void> setAudioConfig(ZegoUIKitAudioConfig config, {ZegoStreamType streamType = ZegoStreamType.main}) async
> ```
>
> - parameters:
>   - `config`: The audio configuration.
>   - `streamType`: The stream type (main, media, screenSharing, or mix).

### enableAEC

> Enable or disable acoustic echo cancellation (AEC).
>
> - function prototype:
>
> ```dart
> void enableAEC(bool enable)
> ```
>
> - parameters:
>   - `enable`: Whether to enable AEC.

### enableHeadphoneAEC

> Enable or disable echo cancellation when using headphones.
>
> - function prototype:
>
> ```dart
> void enableHeadphoneAEC(bool enable)
> ```
>
> - parameters:
>   - `enable`: Whether to enable headphone AEC.

### setAECMode

> Set the echo cancellation mode.
>
> - function prototype:
>
> ```dart
> void setAECMode(ZegoAECMode mode)
> ```
>
> - parameters:
>   - `mode`: The AEC mode (Aggressive, Medium, or Soft).

### enableAGC

> Enable or disable automatic gain control (AGC).
>
> - function prototype:
>
> ```dart
> void enableAGC(bool enable)
> ```
>
> - parameters:
>   - `enable`: Whether to enable AGC.

### enableANS

> Enable or disable noise suppression (ANS).
>
> - function prototype:
>
> ```dart
> void enableANS(bool enable)
> ```
>
> - parameters:
>   - `enable`: Whether to enable ANS.

### enableTransientANS

> Enable or disable transient noise suppression.
>
> - function prototype:
>
> ```dart
> void enableTransientANS(bool enable)
> ```
>
> - parameters:
>   - `enable`: Whether to enable transient ANS.

### setANSMode

> Set the noise suppression mode.
>
> - function prototype:
>
> ```dart
> void setANSMode(ZegoANSMode mode)
> ```
>
> - parameters:
>   - `mode`: The ANS mode (Aggressive, Medium, or Soft).

### setVideoConfig

> Set the video configuration.
>
> - function prototype:
>
> ```dart
> Future<void> setVideoConfig(ZegoUIKitVideoConfig config, {ZegoStreamType streamType = ZegoStreamType.main}) async
> ```
>
> - parameters:
>   - `config`: The video configuration.
>   - `streamType`: The stream type (main, media, screenSharing, or mix).

### enableTrafficControl

> Enable or disable traffic control.
>
> - function prototype:
>
> ```dart
> Future<void> enableTrafficControl(bool enabled, List<ZegoUIKitTrafficControlProperty> properties, {ZegoUIKitVideoConfig? minimizeVideoConfig, bool isFocusOnRemote = true, ZegoStreamType streamType = ZegoStreamType.main}) async
> ```
>
> - parameters:
>   - `enabled`: Whether to enable traffic control.
>   - `properties`: The traffic control properties.
>   - `minimizeVideoConfig`: The minimized video configuration.
>   - `isFocusOnRemote`: Whether to focus on remote video.
>   - `streamType`: The stream type.

### enableVideoMirroring

> Enable or disable video mirroring.
>
> - function prototype:
>
> ```dart
> void enableVideoMirroring(bool isVideoMirror)
> ```
>
> - parameters:
>   - `isVideoMirror`: Whether to enable video mirroring.

### setAudioVideoResourceMode

> Set the audio/video resource mode.
>
> - function prototype:
>
> ```dart
> void setAudioVideoResourceMode(ZegoAudioVideoResourceMode mode)
> ```
>
> - parameters:
>   - `mode`: The resource mode.

### enableSyncDeviceStatusBySEI

> Enable or disable synchronizing device status by SEI.
>
> - function prototype:
>
> ```dart
> void enableSyncDeviceStatusBySEI(bool value)
> ```
>
> - parameters:
>   - `value`: Whether to enable device status synchronization.

### sendCustomSEI

> Send custom SEI (Supplemental Enhancement Information) data.
>
> - function prototype:
>
> ```dart
> Future<bool> sendCustomSEI(Map<String, dynamic> seiData, {ZegoStreamType streamType = ZegoStreamType.main}) async
> ```
>
> - parameters:
>   - `seiData`: The custom SEI data.
>   - `streamType`: The stream type.
>
> - returns:
>   - `bool`: Whether the operation was successful.

### getAudioVideoViewNotifier

> Get the audio/video view notifier for a user.
>
> - function prototype:
>
> ```dart
> ValueNotifier<Widget?> getAudioVideoViewNotifier(String? userID, {ZegoStreamType streamType = ZegoStreamType.main})
> ```
>
> - parameters:
>   - `userID`: The user ID. If null, returns the local user's view.
>   - `streamType`: The stream type.
>
> - returns:
>   - `ValueNotifier<Widget?>`: The audio/video view notifier.

### getAudioVideoViewIDNotifier

> Get the audio/video view ID notifier for a user.
>
> - function prototype:
>
> ```dart
> ValueNotifier<int?> getAudioVideoViewIDNotifier(String? userID, {ZegoStreamType streamType = ZegoStreamType.main})
> ```
>
> - parameters:
>   - `userID`: The user ID. If null, returns the local user's view ID.
>   - `streamType`: The stream type.
>
> - returns:
>   - `ValueNotifier<int?>`: The audio/video view ID notifier.

### getAudioVideoQualityNotifier

> Get the audio/video quality notifier for a user.
>
> - function prototype:
>
> ```dart
> ValueNotifier<ZegoUIKitPublishStreamQuality> getAudioVideoQualityNotifier(String? userID, {ZegoStreamType streamType = ZegoStreamType.main})
> ```
>
> - parameters:
>   - `userID`: The user ID. If null, returns the local user's quality.
>   - `streamType`: The stream type.
>
> - returns:
>   - `ValueNotifier<ZegoUIKitPublishStreamQuality>`: The quality notifier.

### getAudioVideoCapturedAudioFirstFrameNotifier

> Get the captured audio first frame notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getAudioVideoCapturedAudioFirstFrameNotifier(String? userID, {ZegoStreamType streamType = ZegoStreamType.main})
> ```
>
> - parameters:
>   - `userID`: The user ID.
>   - `streamType`: The stream type.
>
> - returns:
>   - `ValueNotifier<bool>`: Whether the first audio frame has been captured.

### getAudioVideoCapturedVideoFirstFrameNotifier

> Get the captured video first frame notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getAudioVideoCapturedVideoFirstFrameNotifier(String? userID, {ZegoStreamType streamType = ZegoStreamType.main})
> ```
>
> - parameters:
>   - `userID`: The user ID.
>   - `streamType`: The stream type.
>
> - returns:
>   - `ValueNotifier<bool>`: Whether the first video frame has been captured.

### getAudioVideoSendAudioFirstFrameNotifier

> Get the sent audio first frame notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getAudioVideoSendAudioFirstFrameNotifier(String? userID, {ZegoStreamType streamType = ZegoStreamType.main})
> ```
>
> - parameters:
>   - `userID`: The user ID.
>   - `streamType`: The stream type.
>
> - returns:
>   - `ValueNotifier<bool>`: Whether the first audio frame has been sent.

### getAudioVideoSendVideoFirstFrameNotifier

> Get the sent video first frame notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getAudioVideoSendVideoFirstFrameNotifier(String? userID, {ZegoStreamType streamType = ZegoStreamType.main})
> ```
>
> - parameters:
>   - `userID`: The user ID.
>   - `streamType`: The stream type.
>
> - returns:
>   - `ValueNotifier<bool>`: Whether the first video frame has been sent.

### getCameraStateNotifier

> Get the camera state notifier for a user.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getCameraStateNotifier(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `ValueNotifier<bool>`: The camera state notifier.

### getUseFrontFacingCameraStateNotifier

> Get the front-facing camera state notifier for a user.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getUseFrontFacingCameraStateNotifier(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `ValueNotifier<bool>`: The front-facing camera state notifier.

### getMicrophoneStateNotifier

> Get the microphone state notifier for a user.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getMicrophoneStateNotifier(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `ValueNotifier<bool>`: The microphone state notifier.

### getAudioOutputDeviceNotifier

> Get the audio output device notifier for a user.
>
> - function prototype:
>
> ```dart
> ValueNotifier<ZegoUIKitAudioRoute> getAudioOutputDeviceNotifier(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `ValueNotifier<ZegoUIKitAudioRoute>`: The audio output device notifier.

### getScreenSharingStateNotifier

> Get the screen sharing state notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getScreenSharingStateNotifier()
> ```
>
> - returns:
>   - `ValueNotifier<bool>`: The screen sharing state notifier.

### getSoundLevelStream

> Get the sound level stream for a user.
>
> - function prototype:
>
> ```dart
> Stream<double> getSoundLevelStream(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `Stream<double>`: The sound level stream.

### getAudioVideoListStream

> Get the audio/video user list stream.
>
> - function prototype:
>
> ```dart
> Stream<List<ZegoUIKitUser>> getAudioVideoListStream()
> ```
>
> - returns:
>   - `Stream<List<ZegoUIKitUser>>`: The audio/video user list stream.

### getAudioVideoList

> Get the list of users with audio/video.
>
> - function prototype:
>
> ```dart
> List<ZegoUIKitUser> getAudioVideoList()
> ```
>
> - returns:
>   - `List<ZegoUIKitUser>`: The list of users with audio/video.

### getScreenSharingListStream

> Get the screen sharing user list stream.
>
> - function prototype:
>
> ```dart
> Stream<List<ZegoUIKitUser>> getScreenSharingListStream()
> ```
>
> - returns:
>   - `Stream<List<ZegoUIKitUser>>`: The screen sharing user list stream.

### getScreenSharingList

> Get the list of users sharing screen.
>
> - function prototype:
>
> ```dart
> List<ZegoUIKitUser> getScreenSharingList()
> ```
>
> - returns:
>   - `List<ZegoUIKitUser>`: The list of users sharing screen.

### getMediaListStream

> Get the media user list stream.
>
> - function prototype:
>
> ```dart
> Stream<List<ZegoUIKitUser>> getMediaListStream()
> ```
>
> - returns:
>   - `Stream<List<ZegoUIKitUser>>`: The media user list stream.

### getMediaList

> Get the list of users with media.
>
> - function prototype:
>
> ```dart
> List<ZegoUIKitUser> getMediaList()
> ```
>
> - returns:
>   - `List<ZegoUIKitUser>`: The list of users with media.

### startSharingScreen

> Start screen sharing.
>
> - function prototype:
>
> ```dart
> Future<void> startSharingScreen() async
> ```

### stopSharingScreen

> Stop screen sharing.
>
> - function prototype:
>
> ```dart
> Future<void> stopSharingScreen() async
> ```

### getVideoSizeNotifier

> Get the video size notifier for a user.
>
> - function prototype:
>
> ```dart
> ValueNotifier<Size> getVideoSizeNotifier(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `ValueNotifier<Size>`: The video size notifier.

### updateTextureRendererOrientation

> Update the texture renderer orientation.
>
> - function prototype:
>
> ```dart
> void updateTextureRendererOrientation(Orientation orientation)
> ```
>
> - parameters:
>   - `orientation`: The orientation (portrait or landscape).

### updateAppOrientation

> Update the app orientation.
>
> - function prototype:
>
> ```dart
> void updateAppOrientation(DeviceOrientation orientation)
> ```
>
> - parameters:
>   - `orientation`: The device orientation.

### updateVideoViewMode

> Update the video view mode.
>
> - function prototype:
>
> ```dart
> void updateVideoViewMode(bool useVideoViewAspectFill)
> ```
>
> - parameters:
>   - `useVideoViewAspectFill`: Whether to use aspect fill mode.

### getReceiveSEIStream

> Get the received SEI event stream.
>
> - function prototype:
>
> ```dart
> Stream<ZegoUIKitReceiveSEIEvent> getReceiveSEIStream()
> ```
>
> - returns:
>   - `Stream<ZegoUIKitReceiveSEIEvent>`: The SEI event stream.

### getReceiveCustomSEIStream

> Get the received custom SEI event stream.
>
> - function prototype:
>
> ```dart
> Stream<ZegoUIKitReceiveSEIEvent> getReceiveCustomSEIStream()
> ```
>
> - returns:
>   - `Stream<ZegoUIKitReceiveSEIEvent>`: The custom SEI event stream.

### getGeneratedStreamID

> Generate a stream ID for a user.
>
> - function prototype:
>
> ```dart
> String getGeneratedStreamID(String userID, String roomID, ZegoStreamType type)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>   - `roomID`: The room ID.
>   - `type`: The stream type.
>
> - returns:
>   - `String`: The generated stream ID.

## CustomCommandService

Provides functionality for sending custom commands.

### sendCustomCommand

> Send a custom command to specific users.
>
> - function prototype:
>
> ```dart
> Future<bool> sendCustomCommand(String command, List<String> toUserIDs) async
> ```
>
> - parameters:
>   - `command`: The custom command to send.
>   - `toUserIDs`: The list of user IDs to send the command to.
>
> - returns:
>   - `bool`: Whether the command was sent successfully.

### getInRoomCommandReceivedStream

> Get the stream of received in-room commands.
>
> - function prototype:
>
> ```dart
> Stream<ZegoInRoomCommandReceivedData> getInRoomCommandReceivedStream()
> ```
>
> - returns:
>   - `Stream<ZegoInRoomCommandReceivedData>`: The stream of received commands.

## DeviceService

## ChannelService

Provides platform channel related functions, such as PIP, device control, and app lifecycle management.

### backToDesktop

> Go back to the desktop (Android only).
>
> - function prototype:
>
> ```dart
> Future<void> backToDesktop({bool nonRoot = false}) async
> ```
>
> - parameters:
>   - `nonRoot`: Whether to exit without finishing the app.

### isLockScreen

> Check if the screen is locked.
>
> - function prototype:
>
> ```dart
> Future<bool> isLockScreen() async
> ```
>
> - returns:
>   - `bool`: Whether the screen is locked.

### checkAppRunning

> Check if the app is running in the foreground.
>
> - function prototype:
>
> ```dart
> Future<bool> checkAppRunning() async
> ```
>
> - returns:
>   - `bool`: Whether the app is running.

### activeAppToForeground

> Bring the app to the foreground.
>
> - function prototype:
>
> ```dart
> Future<void> activeAppToForeground() async
> ```

### stopIOSPIP

> Stop the iOS Picture-in-Picture mode.
>
> - function prototype:
>
> ```dart
> Future<bool> stopIOSPIP() async
> ```
>
> - returns:
>   - `bool`: Whether the operation was successful.

### isIOSInPIP

> Check if iOS is currently in Picture-in-Picture mode.
>
> - function prototype:
>
> ```dart
> Future<bool> isIOSInPIP() async
> ```
>
> - returns:
>   - `bool`: Whether iOS is in PIP mode.

### enableIOSPIP

> Enable Picture-in-Picture mode on iOS.
>
> - function prototype:
>
> ```dart
> Future<void> enableIOSPIP(String streamID, {int aspectWidth = 9, int aspectHeight = 16}) async
> ```
>
> - parameters:
>   - `streamID`: The stream ID to display in PIP.
>   - `aspectWidth`: The aspect ratio width.
>   - `aspectHeight`: The aspect ratio height.

### updateIOSPIPSource

> Update the iOS PIP video source.
>
> - function prototype:
>
> ```dart
> Future<void> updateIOSPIPSource(String streamID) async
> ```
>
> - parameters:
>   - `streamID`: The new stream ID.

### enableIOSPIPAuto

> Enable or disable automatic Picture-in-Picture mode on iOS.
>
> - function prototype:
>
> ```dart
> Future<void> enableIOSPIPAuto(bool isEnabled, {int aspectWidth = 9, int aspectHeight = 16}) async
> ```
>
> - parameters:
>   - `isEnabled`: Whether to enable auto PIP.
>   - `aspectWidth`: The aspect ratio width.
>   - `aspectHeight`: The aspect ratio height.

### enableHardwareDecoder

> Enable or disable hardware video decoding.
>
> - function prototype:
>
> ```dart
> Future<void> enableHardwareDecoder(bool isEnabled) async
> ```
>
> - parameters:
>   - `isEnabled`: Whether to enable hardware decoder.

### enableCustomVideoRender

> Enable or disable custom video rendering.
>
> - function prototype:
>
> ```dart
> Future<void> enableCustomVideoRender(bool isEnabled) async
> ```
>
> - parameters:
>   - `isEnabled`: Whether to enable custom video render.

### onWillPop

> Handle the back button press event (Android only).
>
> - function prototype:
>
> ```dart
> Future<bool> onWillPop(BuildContext context) async
> ```
>
> - parameters:
>   - `context`: The build context.
>
> - returns:
>   - `bool`: Whether the navigation should pop.

### openAppSettings

> Open the app settings page (Android only).
>
> - function prototype:
>
> ```dart
> Future<void> openAppSettings() async
> ```

### requestDismissKeyguard

> Request to dismiss the keyguard.
>
> - function prototype:
>
> ```dart
> Future<void> requestDismissKeyguard() async
> ```

### startPlayingStreamInPIP

> Start playing a stream in Picture-in-Picture mode.
>
> - function prototype:
>
> ```dart
> Future<void> startPlayingStreamInPIP(String streamID) async
> ```
>
> - parameters:
>   - `streamID`: The stream ID.

### stopPlayingStreamInPIP

> Stop playing a stream in Picture-in-Picture mode.
>
> - function prototype:
>
> ```dart
> Future<void> stopPlayingStreamInPIP(String streamID) async
> ```
>
> - parameters:
>   - `streamID`: The stream ID.

## DeviceService

Provides device-related functions, such as getting device information and managing camera and microphone device lists.

### getDeviceInfo

> Get information about the current device.
>
> - function prototype:
>
> ```dart
> Map<String, dynamic> getDeviceInfo()
> ```
>
> - returns:
>   - `Map<String, dynamic>`: The device information.

### getSystemInfo

> Get information about the system.
>
> - function prototype:
>
> ```dart
> Map<String, dynamic> getSystemInfo()
> ```
>
> - returns:
>   - `Map<String, dynamic>`: The system information.

### getCameraList

> Get the list of available cameras.
>
> - function prototype:
>
> ```dart
> List<ZegoDeviceInfo> getCameraList()
> ```
>
> - returns:
>   - `List<ZegoDeviceInfo>`: The list of available cameras.

### getMicrophoneList

> Get the list of available microphones.
>
> - function prototype:
>
> ```dart
> List<ZegoDeviceInfo> getMicrophoneList()
> ```
>
> - returns:
>   - `List<ZegoDeviceInfo>`: The list of available microphones.

### getTurnOnYourCameraRequestStream

> Get the stream of requests to turn on the camera.
>
> - function prototype:
>
> ```dart
> Stream<String> getTurnOnYourCameraRequestStream()
> ```
>
> - returns:
>   - `Stream<String>`: The stream of camera turn-on requests.

### getTurnOnYourMicrophoneRequestStream

> Get the stream of requests to turn on the microphone.
>
> - function prototype:
>
> ```dart
> Stream<ZegoUIKitReceiveTurnOnLocalMicrophoneEvent> getTurnOnYourMicrophoneRequestStream()
> ```
>
> - returns:
>   - `Stream<ZegoUIKitReceiveTurnOnLocalMicrophoneEvent>`: The stream of microphone turn-on requests.

### enableCustomVideoProcessing

> Enable or disable custom video processing.
>
> - function prototype:
>
> ```dart
> Future<void> enableCustomVideoProcessing(bool enable) async
> ```
>
> - parameters:
>   - `enable`: Whether to enable custom video processing.

### getMobileSystemVersionX

> Get the mobile system version (extended version).
>
> - function prototype:
>
> ```dart
> ZegoMobileSystemVersion getMobileSystemVersionX()
> ```
>
> - returns:
>   - `ZegoMobileSystemVersion`: The mobile system version.

### getMobileSystemVersion

> Get the mobile system version.
>
> - function prototype:
>
> ```dart
> ZegoMobileSystemVersion getMobileSystemVersion()
> ```
>
> - returns:
>   - `ZegoMobileSystemVersion`: The mobile system version.

### setAudioDeviceMode

> Set the audio device mode.
>
> - function prototype:
>
> ```dart
> Future<void> setAudioDeviceMode(ZegoUIKitAudioDeviceMode deviceMode) async
> ```
>
> - parameters:
>   - `deviceMode`: The audio device mode.

## EffectService

Provides video effects such as beauty filters and virtual backgrounds.

### setBeautyEffect

> Set beauty effects for the video.
>
> - function prototype:
>
> ```dart
> Future<void> setBeautyEffect(BeautyEffectConfig config) async
> ```
>
> - parameters:
>   - `config`: The beauty effect configuration.

### setVirtualBackground

> Set the virtual background for the video.
>
> - function prototype:
>
> ```dart
> Future<void> setVirtualBackground(VirtualBackgroundConfig config) async
> ```
>
> - parameters:
>   - `config`: The virtual background configuration.

### enableBeauty

> Enable or disable beauty effects.
>
> - function prototype:
>
> ```dart
> Future<void> enableBeauty(bool isOn) async
> ```
>
> - parameters:
>   - `isOn`: Whether to enable beauty effects.

### startEffectsEnv

> Start the effects environment.
>
> - function prototype:
>
> ```dart
> Future<void> startEffectsEnv() async
> ```

### stopEffectsEnv

> Stop the effects environment.
>
> - function prototype:
>
> ```dart
> Future<void> stopEffectsEnv() async
> ```

### setBeautifyValue

> Set the intensity of a specific beautify effect.
>
> - function prototype:
>
> ```dart
> void setBeautifyValue(int value, BeautyEffectType type)
> ```
>
> - parameters:
>   - `value`: The intensity value (0-100).
>   - `type`: The beautify effect type.

### getBeautyValue

> Get the current beauty parameter configuration.
>
> - function prototype:
>
> ```dart
> ZegoEffectsBeautyParam getBeautyValue()
> ```
>
> - returns:
>   - `ZegoEffectsBeautyParam`: The current beauty parameters.

### setVoiceChangerType

> Set the voice changer type.
>
> - function prototype:
>
> ```dart
> void setVoiceChangerType(ZegoVoiceChangerPreset voicePreset)
> ```
>
> - parameters:
>   - `voicePreset`: The voice changer preset.

### setReverbType

> Set the reverb type.
>
> - function prototype:
>
> ```dart
> void setReverbType(ZegoReverbPreset reverbPreset)
> ```
>
> - parameters:
>   - `reverbPreset`: The reverb preset.

### resetSoundEffect

> Reset all sound effects to default.
>
> - function prototype:
>
> ```dart
> Future<void> resetSoundEffect() async
> ```

### resetBeautyEffect

> Reset all beauty effects to default.
>
> - function prototype:
>
> ```dart
> Future<void> resetBeautyEffect() async
> ```

## EventService

Provides functionality for event listening and unlistening.

### listen

> Listen to a specific event.
>
> - function prototype:
>
> ```dart
> void listen<T>(String eventName, void Function(T) callback)
> ```
>
> - parameters:
>   - `eventName`: The name of the event to listen to.
>   - `callback`: The function to call when the event occurs.

### unlisten

> Stop listening to a specific event.
>
> - function prototype:
>
> ```dart
> void unlisten<T>(String eventName, [void Function(T)? callback])
> ```
>
> - parameters:
>   - `eventName`: The name of the event to stop listening to.
>   - `callback`: The callback function to remove. If null, removes all callbacks for this event.

### enableEventUninitOnRoomLeaved

> Enable or disable automatic uninitialization when leaving a room.
>
> - function prototype:
>
> ```dart
> void enableEventUninitOnRoomLeaved(bool enabled)
> ```
>
> - parameters:
>   - `enabled`: Whether to enable automatic uninitialization.

### registerExpressEvent

> Register an Express engine event handler.
>
> - function prototype:
>
> ```dart
> void registerExpressEvent(ZegoUIKitExpressEventInterface event)
> ```
>
> - parameters:
>   - `event`: The Express event interface to register.

### unregisterExpressEvent

> Unregister an Express engine event handler.
>
> - function prototype:
>
> ```dart
> void unregisterExpressEvent(ZegoUIKitExpressEventInterface event)
> ```
>
> - parameters:
>   - `event`: The Express event interface to unregister.

## LoggerService

Provides logging functionality.

### logInfo

> Log information level message.
>
> - function prototype:
>
> ```dart
> void logInfo(String tag, String message)
> ```
>
> - parameters:
>   - `tag`: The tag for the log message.
>   - `message`: The message to log.

### logWarning

> Log warning level message.
>
> - function prototype:
>
> ```dart
> void logWarning(String tag, String message)
> ```
>
> - parameters:
>   - `tag`: The tag for the log message.
>   - `message`: The message to log.

### logError

> Log error level message.
>
> - function prototype:
>
> ```dart
> void logError(String tag, String message, [dynamic error, StackTrace? stackTrace])
> ```
>
> - parameters:
>   - `tag`: The tag for the log message.
>   - `message`: The message to log.
>   - `error`: The error object, if any.
>   - `stackTrace`: The stack trace, if any.

### initLog

> Initialize the logging system.
>
> - function prototype:
>
> ```dart
> Future<void> initLog() async
> ```

### clearLogs

> Clear all logs.
>
> - function prototype:
>
> ```dart
> Future<void> clearLogs() async
> ```

### exportLogs

> Export logs to a file.
>
> - function prototype:
>
> ```dart
> Future<bool> exportLogs({String? title, String? content, String? fileName, List<ZegoLogExporterFileType> fileTypes = const [...], List<ZegoLogExporterDirectoryType> directories = const [...], void Function(double progress)? onProgress}) async
> ```
>
> - parameters:
>   - `title`: Export title, defaults to current timestamp.
>   - `content`: Export content description.
>   - `fileName`: Zip file name (without extension).
>   - `fileTypes`: List of file types to collect.
>   - `directories`: List of directory types to collect.
>   - `onProgress`: Optional progress callback (0.0 to 1.0).
>
> - returns:
>   - `bool`: Whether the export was successful.

## MediaService

Provides media playback related functions.

### startMediaPlayer

> Start playing media from a source.
>
> - function prototype:
>
> ```dart
> Future<int> startMediaPlayer(String source) async
> ```
>
> - parameters:
>   - `source`: The source of the media to play.
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### pauseMediaPlayer

> Pause the media player.
>
> - function prototype:
>
> ```dart
> Future<int> pauseMediaPlayer() async
> ```
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### resumeMediaPlayer

> Resume the media player.
>
> - function prototype:
>
> ```dart
> Future<int> resumeMediaPlayer() async
> ```
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### stopMediaPlayer

> Stop the media player.
>
> - function prototype:
>
> ```dart
> Future<int> stopMediaPlayer() async
> ```
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### registerMediaEvent

> Register a media event handler.
>
> - function prototype:
>
> ```dart
> void registerMediaEvent(ZegoUIKitMediaEventInterface event)
> ```
>
> - parameters:
>   - `event`: The media event interface to register.

### unregisterMediaEvent

> Unregister a media event handler.
>
> - function prototype:
>
> ```dart
> void unregisterMediaEvent(ZegoUIKitMediaEventInterface event)
> ```
>
> - parameters:
>   - `event`: The media event interface to unregister.

### playMedia

> Start playing media with full configuration.
>
> - function prototype:
>
> ```dart
> Future<ZegoUIKitMediaPlayResult> playMedia({required String filePathOrURL, bool enableRepeat = false, bool autoStart = true}) async
> ```
>
> - parameters:
>   - `filePathOrURL`: The file path or URL of the media.
>   - `enableRepeat`: Whether to enable repeat playback.
>   - `autoStart`: Whether to start playing automatically.
>
> - returns:
>   - `ZegoUIKitMediaPlayResult`: The result of the media playback.

### startMedia

> Start media playback.
>
> - function prototype:
>
> ```dart
> Future<void> startMedia() async
> ```

### stopMedia

> Stop media playback.
>
> - function prototype:
>
> ```dart
> Future<void> stopMedia() async
> ```

### pauseMedia

> Pause media playback.
>
> - function prototype:
>
> ```dart
> Future<void> pauseMedia() async
> ```

### resumeMedia

> Resume media playback.
>
> - function prototype:
>
> ```dart
> Future<void> resumeMedia() async
> ```

### destroyMedia

> Destroy the media player.
>
> - function prototype:
>
> ```dart
> Future<void> destroyMedia() async
> ```

### seekTo

> Seek to a specific position in the media.
>
> - function prototype:
>
> ```dart
> Future<ZegoUIKitMediaSeekToResult> seekTo(int millisecond) async
> ```
>
> - parameters:
>   - `millisecond`: The target position in milliseconds.
>
> - returns:
>   - `ZegoUIKitMediaSeekToResult`: The seek result.

### setMediaVolume

> Set the media player volume.
>
> - function prototype:
>
> ```dart
> Future<void> setMediaVolume(int volume, {bool isSyncToRemote = false}) async
> ```
>
> - parameters:
>   - `volume`: The volume level (0-100).
>   - `isSyncToRemote`: Whether to sync the volume to remote.

### getMediaVolume

> Get the current media player volume.
>
> - function prototype:
>
> ```dart
> int getMediaVolume()
> ```
>
> - returns:
>   - `int`: The current volume level.

### muteMediaLocal

> Mute the media player locally.
>
> - function prototype:
>
> ```dart
> Future<void> muteMediaLocal(bool mute) async
> ```
>
> - parameters:
>   - `mute`: Whether to mute the media.

### getMediaMuteNotifier

> Get the media mute state notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getMediaMuteNotifier()
> ```
>
> - returns:
>   - `ValueNotifier<bool>`: The mute state notifier.

### getMediaVolumeNotifier

> Get the media volume notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<int> getMediaVolumeNotifier()
> ```
>
> - returns:
>   - `ValueNotifier<int>`: The volume notifier.

### getMediaTotalDuration

> Get the total duration of the media.
>
> - function prototype:
>
> ```dart
> int getMediaTotalDuration()
> ```
>
> - returns:
>   - `int`: The total duration in milliseconds.

### getMediaCurrentProgress

> Get the current playback progress.
>
> - function prototype:
>
> ```dart
> int getMediaCurrentProgress()
> ```
>
> - returns:
>   - `int`: The current position in milliseconds.

### getMediaCurrentProgressNotifier

> Get the current progress notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<int> getMediaCurrentProgressNotifier()
> ```
>
> - returns:
>   - `ValueNotifier<int>`: The progress notifier.

### getMediaType

> Get the media type.
>
> - function prototype:
>
> ```dart
> ZegoUIKitMediaType getMediaType()
> ```
>
> - returns:
>   - `ZegoUIKitMediaType`: The media type.

### getMediaTypeNotifier

> Get the media type notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<ZegoUIKitMediaType> getMediaTypeNotifier()
> ```
>
> - returns:
>   - `ValueNotifier<ZegoUIKitMediaType>`: The media type notifier.

### getMediaPlayStateNotifier

> Get the media play state notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<ZegoUIKitMediaPlayState> getMediaPlayStateNotifier()
> ```
>
> - returns:
>   - `ValueNotifier<ZegoUIKitMediaPlayState>`: The play state notifier.

### pickPureAudioMediaFile

> Pick a pure audio media file.
>
> - function prototype:
>
> ```dart
> Future<List<ZegoUIKitPlatformFile>> pickPureAudioMediaFile() async
> ```
>
> - returns:
>   - `List<ZegoUIKitPlatformFile>`: The list of selected audio files.

### pickVideoMediaFile

> Pick a video media file.
>
> - function prototype:
>
> ```dart
> Future<List<ZegoUIKitPlatformFile>> pickVideoMediaFile() async
> ```
>
> - returns:
>   - `List<ZegoUIKitPlatformFile>`: The list of selected video files.

### pickMediaFile

> Pick a media file with optional format restrictions.
>
> - function prototype:
>
> ```dart
> Future<List<ZegoUIKitPlatformFile>> pickMediaFile({List<String>? allowedExtensions}) async
> ```
>
> - parameters:
>   - `allowedExtensions`: Optional list of allowed file extensions.
>
> - returns:
>   - `List<ZegoUIKitPlatformFile>`: The list of selected media files.

### getMediaInfo

> Get the current media information.
>
> - function prototype:
>
> ```dart
> ZegoUIKitMediaInfo getMediaInfo()
> ```
>
> - returns:
>   - `ZegoUIKitMediaInfo`: The media information.

## MessageService

Provides message sending functionality, including broadcast messages, barrage messages, and custom messages.

### sendBroadcastMessage

> Send a broadcast message to everyone in the room.
>
> - function prototype:
>
> ```dart
> Future<ZegoIMSendResult> sendBroadcastMessage(String message) async
> ```
>
> - parameters:
>   - `message`: The message to send.
>
> - returns:
>   - `ZegoIMSendResult`: The result of sending the message.

### sendBarrageMessage

> Send a barrage message to everyone in the room.
>
> - function prototype:
>
> ```dart
> Future<ZegoIMSendResult> sendBarrageMessage(String message) async
> ```
>
> - parameters:
>   - `message`: The message to send.
>
> - returns:
>   - `ZegoIMSendResult`: The result of sending the message.

### sendCustomMessage

> Send a custom message to specific users.
>
> - function prototype:
>
> ```dart
> Future<ZegoIMSendResult> sendCustomMessage(String message, List<String> toUserIDs) async
> ```
>
> - parameters:
>   - `message`: The message to send.
>   - `toUserIDs`: The list of user IDs to send the message to.
>
> - returns:
>   - `ZegoIMSendResult`: The result of sending the message.

### sendInRoomMessage

> Send an in-room message.
>
> - function prototype:
>
> ```dart
> Future<bool> sendInRoomMessage(String message, {ZegoInRoomMessageType type = ZegoInRoomMessageType.broadcastMessage}) async
> ```
>
> - parameters:
>   - `message`: The message to send.
>   - `type`: The message type (broadcast or barrage).
>
> - returns:
>   - `bool`: Whether the message was sent successfully.

### resendInRoomMessage

> Re-send an in-room message.
>
> - function prototype:
>
> ```dart
> Future<bool> resendInRoomMessage(ZegoInRoomMessage message, {ZegoInRoomMessageType type = ZegoInRoomMessageType.broadcastMessage}) async
> ```
>
> - parameters:
>   - `message`: The message to re-send.
>   - `type`: The message type.
>
> - returns:
>   - `bool`: Whether the message was re-sent successfully.

### getInRoomMessages

> Get all in-room messages.
>
> - function prototype:
>
> ```dart
> List<ZegoInRoomMessage> getInRoomMessages({ZegoInRoomMessageType type = ZegoInRoomMessageType.broadcastMessage})
> ```
>
> - parameters:
>   - `type`: The message type.
>
> - returns:
>   - `List<ZegoInRoomMessage>`: The list of messages.

### getInRoomMessageListStream

> Get the stream of in-room message lists.
>
> - function prototype:
>
> ```dart
> Stream<List<ZegoInRoomMessage>> getInRoomMessageListStream({ZegoInRoomMessageType type = ZegoInRoomMessageType.broadcastMessage})
> ```
>
> - parameters:
>   - `type`: The message type.
>
> - returns:
>   - `Stream<List<ZegoInRoomMessage>>`: The message list stream.

### getInRoomMessageStream

> Get the stream of received in-room messages.
>
> - function prototype:
>
> ```dart
> Stream<ZegoInRoomMessage> getInRoomMessageStream({ZegoInRoomMessageType type = ZegoInRoomMessageType.broadcastMessage})
> ```
>
> - parameters:
>   - `type`: The message type.
>
> - returns:
>   - `Stream<ZegoInRoomMessage>`: The message stream.

### getInRoomLocalMessageStream

> Get the stream of locally sent in-room messages.
>
> - function prototype:
>
> ```dart
> Stream<ZegoInRoomMessage> getInRoomLocalMessageStream({ZegoInRoomMessageType type = ZegoInRoomMessageType.broadcastMessage})
> ```
>
> - parameters:
>   - `type`: The message type.
>
> - returns:
>   - `Stream<ZegoInRoomMessage>`: The local message stream.

### clearMessage

> Clear in-room messages.
>
> - function prototype:
>
> ```dart
> Future<bool> clearMessage({ZegoInRoomMessageType type = ZegoInRoomMessageType.broadcastMessage, bool clearRemote = true}) async
> ```
>
> - parameters:
>   - `type`: The message type.
>   - `clearRemote`: Whether to clear remote messages.
>
> - returns:
>   - `bool`: Whether the operation was successful.

## MixerService

Provides stream mixing functionality for combining multiple video streams into one.

### startMixerTask

> Start a mixer task.
>
> - function prototype:
>
> ```dart
> Future<int> startMixerTask(ZegoMixerTask task) async
> ```
>
> - parameters:
>   - `task`: The mixer task configuration.
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### stopMixerTask

> Stop a mixer task.
>
> - function prototype:
>
> ```dart
> Future<int> stopMixerTask(String taskID) async
> ```
>
> - parameters:
>   - `taskID`: The ID of the mixer task to stop.
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### updateMixerLayout

> Update the layout of a mixer task.
>
> - function prototype:
>
> ```dart
> Future<int> updateMixerLayout(String taskID, List<ZegoMixerInput> mixerInputs) async
> ```
>
> - parameters:
>   - `taskID`: The ID of the mixer task to update.
>   - `mixerInputs`: The new mixer inputs for the layout.
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### startPlayAnotherRoomAudioVideo

> Start playing audio and video from another room.
>
> - function prototype:
>
> ```dart
> Future<void> startPlayAnotherRoomAudioVideo(String roomID, String userID, {String userName = '', PlayerStateUpdateCallback? onPlayerStateUpdated}) async
> ```
>
> - parameters:
>   - `roomID`: The room ID.
>   - `userID`: The user ID.
>   - `userName`: The user name.
>   - `onPlayerStateUpdated`: Optional callback for player state updates.

### stopPlayAnotherRoomAudioVideo

> Stop playing audio and video from another room.
>
> - function prototype:
>
> ```dart
> Future<void> stopPlayAnotherRoomAudioVideo(String userID) async
> ```
>
> - parameters:
>   - `userID`: The user ID.

### startPlayMixAudioVideo

> Start playing mixed audio and video.
>
> - function prototype:
>
> ```dart
> Future<void> startPlayMixAudioVideo(String mixerID, List<ZegoUIKitUser> users, Map<String, int> userSoundIDs, {PlayerStateUpdateCallback? onPlayerStateUpdated}) async
> ```
>
> - parameters:
>   - `mixerID`: The mixer ID.
>   - `users`: The list of users.
>   - `userSoundIDs`: Map of user IDs to sound IDs.
>   - `onPlayerStateUpdated`: Optional callback.

### stopPlayMixAudioVideo

> Stop playing mixed audio and video.
>
> - function prototype:
>
> ```dart
> Future<void> stopPlayMixAudioVideo(String mixerID) async
> ```
>
> - parameters:
>   - `mixerID`: The mixer ID.

### getMixAudioVideoViewNotifier

> Get the mixed audio/video view notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<Widget?> getMixAudioVideoViewNotifier(String mixerID)
> ```
>
> - parameters:
>   - `mixerID`: The mixer ID.
>
> - returns:
>   - `ValueNotifier<Widget?>`: The view notifier.

### getMixAudioVideoCameraStateNotifier

> Get the mixed audio/video camera state notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getMixAudioVideoCameraStateNotifier(String mixerID, String userID)
> ```
>
> - parameters:
>   - `mixerID`: The mixer ID.
>   - `userID`: The user ID.
>
> - returns:
>   - `ValueNotifier<bool>`: The camera state notifier.

### getMixAudioVideoMicrophoneStateNotifier

> Get the mixed audio/video microphone state notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getMixAudioVideoMicrophoneStateNotifier(String mixerID, String userID)
> ```
>
> - parameters:
>   - `mixerID`: The mixer ID.
>   - `userID`: The user ID.
>
> - returns:
>   - `ValueNotifier<bool>`: The microphone state notifier.

### getMixAudioVideoLoadedNotifier

> Get the mixed audio/video loaded state notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<bool> getMixAudioVideoLoadedNotifier(String mixerID)
> ```
>
> - parameters:
>   - `mixerID`: The mixer ID.
>
> - returns:
>   - `ValueNotifier<bool>`: The loaded state notifier.

### getMixedSoundLevelsStream

> Get the stream of mixed sound levels.
>
> - function prototype:
>
> ```dart
> Stream<Map<int, double>> getMixedSoundLevelsStream()
> ```
>
> - returns:
>   - `Stream<Map<int, double>>`: The sound levels stream.

### getMixedSoundLevelStream

> Get the sound level stream for a user in mixed stream.
>
> - function prototype:
>
> ```dart
> Stream<double> getMixedSoundLevelStream(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `Stream<double>`: The sound level stream.

### getUserInMixerStream

> Get user information from mixer stream.
>
> - function prototype:
>
> ```dart
> ZegoUIKitUser getUserInMixerStream(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `ZegoUIKitUser`: The user information.

### getMixerStreamUsers

> Get the list of users in a mixer stream.
>
> - function prototype:
>
> ```dart
> List<ZegoUIKitUser> getMixerStreamUsers(String mixerStreamID)
> ```
>
> - parameters:
>   - `mixerStreamID`: The mixer stream ID.
>
> - returns:
>   - `List<ZegoUIKitUser>`: The list of users.

### getMixerUserListStream

> Get the mixer user list stream.
>
> - function prototype:
>
> ```dart
> Stream<List<ZegoUIKitUser>> getMixerUserListStream(String mixerStreamID)
> ```
>
> - parameters:
>   - `mixerStreamID`: The mixer stream ID.
>
> - returns:
>   - `Stream<List<ZegoUIKitUser>>`: The user list stream.

## PluginService

Provides plugin registration and unregistration functionality.

### registerPlugin

> Register a plugin.
>
> - function prototype:
>
> ```dart
> void registerPlugin(IZegoUIKitPlugin plugin)
> ```
>
> - parameters:
>   - `plugin`: The plugin to register.

### unregisterPlugin

> Unregister a plugin.
>
> - function prototype:
>
> ```dart
> void unregisterPlugin(IZegoUIKitPlugin plugin)
> ```
>
> - parameters:
>   - `plugin`: The plugin to unregister.

### pluginsInstallNotifier

> Get the plugins install state notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<List<ZegoUIKitPluginType>> pluginsInstallNotifier()
> ```
>
> - returns:
>   - `ValueNotifier<List<ZegoUIKitPluginType>>`: The plugins install state notifier.

### installPlugins

> Install multiple plugins at once.
>
> - function prototype:
>
> ```dart
> void installPlugins(List<IZegoUIKitPlugin> plugins)
> ```
>
> - parameters:
>   - `plugins`: The list of plugins to install.

### uninstallPlugins

> Uninstall multiple plugins at once.
>
> - function prototype:
>
> ```dart
> void uninstallPlugins(List<IZegoUIKitPlugin> plugins)
> ```
>
> - parameters:
>   - `plugins`: The list of plugins to uninstall.

### adapterService

> Get the plugin adapter service.
>
> - function prototype:
>
> ```dart
> ZegoPluginAdapterService adapterService()
> ```
>
> - returns:
>   - `ZegoPluginAdapterService`: The adapter service.

### getPlugin

> Get a plugin by type.
>
> - function prototype:
>
> ```dart
> IZegoUIKitPlugin? getPlugin(ZegoUIKitPluginType type)
> ```
>
> - parameters:
>   - `type`: The plugin type.
>
> - returns:
>   - `IZegoUIKitPlugin?`: The plugin, or null if not found.

### getSignalingPlugin

> Get the signaling plugin instance.
>
> - function prototype:
>
> ```dart
> ZegoUIKitSignalingPluginImpl getSignalingPlugin()
> ```
>
> - returns:
>   - `ZegoUIKitSignalingPluginImpl`: The signaling plugin instance.

### getBeautyPlugin

> Get the beauty plugin instance.
>
> - function prototype:
>
> ```dart
> ZegoUIKitBeautyPluginImpl getBeautyPlugin()
> ```
>
> - returns:
>   - `ZegoUIKitBeautyPluginImpl`: The beauty plugin instance.

## RoomService

Provides room-related functions, such as joining a room, leaving a room, and updating room properties.

### joinRoom

> Join a room.
>
> - function prototype:
>
> ```dart
> Future<int> joinRoom(String roomID, ZegoRoomConfig config) async
> ```
>
> - parameters:
>   - `roomID`: The ID of the room to join.
>   - `config`: The room configuration.
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### leaveRoom

> Leave the current room.
>
> - function prototype:
>
> ```dart
> Future<int> leaveRoom() async
> ```
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### updateRoomProperties

> Update the properties of the current room.
>
> - function prototype:
>
> ```dart
> Future<int> updateRoomProperties(Map<String, String> properties) async
> ```
>
> - parameters:
>   - `properties`: The properties to update.
>
> - returns:
>   - `int`: Error code, 0 indicates success.

### isRoomLogin

> Check if the current user is logged into a room.
>
> - function prototype:
>
> ```dart
> bool get isRoomLogin
> ```
>
> - returns:
>   - `bool`: Whether the user is logged in.

### renewRoomToken

> Renew the room token.
>
> - function prototype:
>
> ```dart
> Future<void> renewRoomToken(String token) async
> ```
>
> - parameters:
>   - `token`: The new token.

### getRoom

> Get the current room object.
>
> - function prototype:
>
> ```dart
> ZegoUIKitRoom getRoom()
> ```
>
> - returns:
>   - `ZegoUIKitRoom`: The room object.

### getRoomStateStream

> Get the room state stream.
>
> - function prototype:
>
> ```dart
> ValueNotifier<ZegoUIKitRoomState> getRoomStateStream()
> ```
>
> - returns:
>   - `ValueNotifier<ZegoUIKitRoomState>`: The room state notifier.

### setRoomProperty

> Set a single room property.
>
> - function prototype:
>
> ```dart
> Future<bool> setRoomProperty(String key, String value) async
> ```
>
> - parameters:
>   - `key`: The property key.
>   - `value`: The property value.
>
> - returns:
>   - `bool`: Whether the operation was successful.

### getRoomProperties

> Get all room properties.
>
> - function prototype:
>
> ```dart
> Map<String, RoomProperty> getRoomProperties()
> ```
>
> - returns:
>   - `Map<String, RoomProperty>`: All room properties.

### getRoomPropertyStream

> Get the stream of room property updates.
>
> - function prototype:
>
> ```dart
> Stream<RoomProperty> getRoomPropertyStream()
> ```
>
> - returns:
>   - `Stream<RoomProperty>`: The property update stream.

### getRoomTokenExpiredStream

> Get the stream of room token expiration events.
>
> - function prototype:
>
> ```dart
> Stream<int> getRoomTokenExpiredStream()
> ```
>
> - returns:
>   - `Stream<int>`: The token expiration stream.

### getRoomPropertiesStream

> Get the stream of room properties updates.
>
> - function prototype:
>
> ```dart
> Stream<Map<String, RoomProperty>> getRoomPropertiesStream()
> ```
>
> - returns:
>   - `Stream<Map<String, RoomProperty>>`: The properties update stream.

### getNetworkStateNotifier

> Get the network state notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<ZegoUIKitNetworkState> getNetworkStateNotifier()
> ```
>
> - returns:
>   - `ValueNotifier<ZegoUIKitNetworkState>`: The network state notifier.

### getNetworkState

> Get the current network state.
>
> - function prototype:
>
> ```dart
> ZegoUIKitNetworkState getNetworkState()
> ```
>
> - returns:
>   - `ZegoUIKitNetworkState`: The current network state.

### getNetworkModeStream

> Get the network mode stream.
>
> - function prototype:
>
> ```dart
> Stream<ZegoUIKitNetworkState> getNetworkModeStream()
> ```
>
> - returns:
>   - `Stream<ZegoUIKitNetworkState>`: The network mode stream.

## UIKitService

Provides UIKit initialization and uninitialization functionality.

### init

> Initialize the UIKit with the given configuration.
>
> - function prototype:
>
> ```dart
> Future<void> init(ZegoUIKitConfig config) async
> ```
>
> - parameters:
>   - `config`: The UIKit configuration.

### uninit

> Uninitialize the UIKit.
>
> - function prototype:
>
> ```dart
> Future<void> uninit() async
> ```

### getVersion

> Get the version of the UIKit.
>
> - function prototype:
>
> ```dart
> String getVersion()
> ```
>
> - returns:
>   - `String`: The version string.

## UserService

Provides user management functionality, such as getting user information.

### getLocalUser

> Get the local user information.
>
> - function prototype:
>
> ```dart
> ZegoUIKitUser getLocalUser()
> ```
>
> - returns:
>   - `ZegoUIKitUser`: The local user information.

### getAllUsers

> Get the list of all users in the room.
>
> - function prototype:
>
> ```dart
> List<ZegoUIKitUser> getAllUsers()
> ```
>
> - returns:
>   - `List<ZegoUIKitUser>`: The list of all users in the room.

### getUserByID

> Get user information by user ID.
>
> - function prototype:
>
> ```dart
> ZegoUIKitUser? getUserByID(String userID)
> ```
>
> - parameters:
>   - `userID`: The ID of the user to get information for.
>
> - returns:
>   - `ZegoUIKitUser?`: The user information, or null if the user is not found.

### login

> Login a user.
>
> - function prototype:
>
> ```dart
> void login(String id, String name)
> ```
>
> - parameters:
>   - `id`: The user ID.
>   - `name`: The user name.

### logout

> Logout the current user.
>
> - function prototype:
>
> ```dart
> void logout()
> ```

### getRemoteUsers

> Get the list of remote users.
>
> - function prototype:
>
> ```dart
> List<ZegoUIKitUser> getRemoteUsers()
> ```
>
> - returns:
>   - `List<ZegoUIKitUser>`: The list of remote users.

### getLeaveUsers

> Get the list of users who have left the room.
>
> - function prototype:
>
> ```dart
> List<ZegoUIKitUser> getLeaveUsers()
> ```
>
> - returns:
>   - `List<ZegoUIKitUser>`: The list of users who have left.

### clearLeaveUsers

> Clear the list of users who have left the room.
>
> - function prototype:
>
> ```dart
> void clearLeaveUsers()
> ```

### getLeaveUsersCache

> Get the cached list of users who have left the room.
>
> - function prototype:
>
> ```dart
> Future<List<ZegoUIKitUser>> getLeaveUsersCache(String roomID) async
> ```
>
> - parameters:
>   - `roomID`: The room ID.
>
> - returns:
>   - `List<ZegoUIKitUser>`: The cached list of users who have left.

### clearLeaveUsersCache

> Clear the cached list of users who have left the room.
>
> - function prototype:
>
> ```dart
> Future<void> clearLeaveUsersCache(String roomID) async
> ```
>
> - parameters:
>   - `roomID`: The room ID.

### getDeletedStreamUserIDs

> Get the list of user IDs whose streams have been deleted.
>
> - function prototype:
>
> ```dart
> Future<List<ZegoUIKitUser>> getDeletedStreamUserIDs(String roomID) async
> ```
>
> - parameters:
>   - `roomID`: The room ID.
>
> - returns:
>   - `List<ZegoUIKitUser>`: The list of users.

### clearDeletedStreamUserIDs

> Clear the list of deleted stream user IDs.
>
> - function prototype:
>
> ```dart
> Future<void> clearDeletedStreamUserIDs(String roomID) async
> ```
>
> - parameters:
>   - `roomID`: The room ID.

### getUser

> Get user information by user ID.
>
> - function prototype:
>
> ```dart
> ZegoUIKitUser getUser(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `ZegoUIKitUser`: The user information.

### getInRoomUserAttributesNotifier

> Get the in-room user attributes notifier.
>
> - function prototype:
>
> ```dart
> ValueNotifier<ZegoUIKitUserAttributes> getInRoomUserAttributesNotifier(String userID)
> ```
>
> - parameters:
>   - `userID`: The user ID.
>
> - returns:
>   - `ValueNotifier<ZegoUIKitUserAttributes>`: The user attributes notifier.

### getUserListStream

> Get the stream of user list updates.
>
> - function prototype:
>
> ```dart
> Stream<List<ZegoUIKitUser>> getUserListStream()
> ```
>
> - returns:
>   - `Stream<List<ZegoUIKitUser>>`: The user list stream.

### getUserJoinStream

> Get the stream of user join events.
>
> - function prototype:
>
> ```dart
> Stream<List<ZegoUIKitUser>> getUserJoinStream()
> ```
>
> - returns:
>   - `Stream<List<ZegoUIKitUser>>`: The user join stream.

### getUserLeaveStream

> Get the stream of user leave events.
>
> - function prototype:
>
> ```dart
> Stream<List<ZegoUIKitUser>> getUserLeaveStream()
> ```
>
> - returns:
>   - `Stream<List<ZegoUIKitUser>>`: The user leave stream.

### removeUserFromRoom

> Remove a user from the room.
>
> - function prototype:
>
> ```dart
> Future<bool> removeUserFromRoom(List<String> userIDs) async
> ```
>
> - parameters:
>   - `userIDs`: The list of user IDs to remove.
>
> - returns:
>   - `bool`: Whether the operation was successful.

### getMeRemovedFromRoomStream

> Get the stream of events when the current user is removed from the room.
>
> - function prototype:
>
> ```dart
> Stream<String> getMeRemovedFromRoomStream()
> ```
>
> - returns:
>   - `Stream<String>`: The stream of removal events.