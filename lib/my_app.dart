import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_trial/secret.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //ClientRoleType role = ClientRoleType.clientRoleBroadcaster;
  int uid = 0; // uid of the local user
  int peerUid = 1;

  bool roomCreator = false;
  int? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  RtcEngine? agoraEngine; // Agora engine instance

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey
  = GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  void initState() {
    super.initState();
    // Set up an instance of Agora engine
    setupVideoSDKEngine();
  }


  Future<void> setupVideoSDKEngine() async {
    // retrieve or request microphone permission
    await [Permission.microphone, Permission.camera].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine!.initialize(const RtcEngineContext(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        appId: appID
    ));

    await agoraEngine!.enableVideo();

    // Register the event handler
    agoraEngine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          showMessage("Local user uid:${connection.localUid} joined the channel");
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          showMessage("Remote user uid:$remoteUid joined the channel");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          showMessage("Remote user uid:$remoteUid left the channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Get started with Voice Calling'),
          ),
          body: agoraEngine != null ? SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                // Status text
                SizedBox(
                    height: 40,
                    child:Center(
                        child:_status()
                    )
                ),
                // Button Row
                SizedBox(
                  height: 40,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                          child: const Text("Create Room"),
                          onPressed: () async {
                            debugPrint("Create room channel");
                            await agoraEngine!.joinChannel(token: token, channelId: channel, uid: uid, options: const ChannelMediaOptions(
                              clientRoleType: ClientRoleType.clientRoleBroadcaster,
                              channelProfile: ChannelProfileType.channelProfileCommunication,
                            )).then((value) {
                              roomCreator = true;
                              setState(() {});
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          child: const Text("Join Room"),
                          onPressed: () async {
                            debugPrint("peer join channel");
                            await agoraEngine!.joinChannel(token: token, channelId: channel, uid: uid, options: const ChannelMediaOptions(
                                clientRoleType: ClientRoleType.clientRoleBroadcaster,
                               channelProfile: ChannelProfileType.channelProfileCommunication,
                              publishCameraTrack: true
                            )).then((value) {
                              setState(() {});
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          child: const Text("Leave"),
                          onPressed: () async {
                            debugPrint("local leave the channel");
                            await agoraEngine!.leaveChannel().then((value) {
                              setState(() {});
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                /// local video
                SizedBox(height: 300, width: 400,child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: agoraEngine!,
                    canvas: VideoCanvas(uid: uid),
                  ),
                )),

                /// peer video
                _remoteUid != null ? SizedBox(height: 300, width: 400,child: AgoraVideoView(
                  controller: VideoViewController(
                      rtcEngine: agoraEngine!,
                      canvas: VideoCanvas(uid: _remoteUid)
                  ),
                )) : Container()
              ],
            ),
          ) : const Center(child: CircularProgressIndicator())),
    );
  }

  Widget _status(){
    String statusText;

    if (!_isJoined) {
      statusText = 'Join a channel';
    } else if (_remoteUid == null) {
      statusText = 'Waiting for a remote user to join...';
    } else {
      statusText = 'Connected to remote user, uid:$_remoteUid';
    }

    return Text(
      statusText,
    );
  }
}
