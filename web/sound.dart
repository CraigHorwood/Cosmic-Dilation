part of ld37;
class Sound
{
  static AudioContext context;
  static GainNode gainNode;
  static Sound snd_explosion = new Sound("assets/snd/explosion.wav");
  static Sound snd_laser = new Sound("assets/snd/laser.wav");
  static Sound snd_rocket = new Sound("assets/snd/rocket.wav");
  static Sound snd_switch = new Sound("assets/snd/switch.wav");
  static Sound snd_thud = new Sound("assets/snd/thud.wav");
  static Sound snd_win = new Sound("assets/snd/win.wav");
  static Sound snd_wingame = new Sound("assets/snd/wingame.wav");
  static bool soundFailed = false, soundOn = true;
  static void init()
  {
    try
    {
      context = new AudioContext();
      gainNode = context.createGain();
      gainNode.connectNode(context.destination);
      snd_explosion.load();
      snd_laser.load();
      snd_rocket.load();
      snd_switch.load();
      snd_thud.load();
      snd_win.load();
      snd_wingame.load();
    }
    catch (e)
    {
      soundFailed = true;
      trace(e.toString());
    }
  }
  bool loaded = false;
  HttpRequest request;
  AudioBuffer buffer;
  String path;
  Sound(this.path);
  void load()
  {
    try
    {
      request = new HttpRequest();
      request.responseType = "arraybuffer";
      request.onLoad.listen(onLoad);
      request.open("GET", path, async:true);
      request.send();
    }
    catch (e)
    {
      trace(e.toString());
    }
  }
  void onLoad(ProgressEvent pe)
  {
    context.decodeAudioData(request.response).then((e)
    {
      buffer = e;
      loaded = true;
    });
  }
  void play()
  {
    if (!loaded || soundFailed || !soundOn) return;
    try
    {
      AudioBufferSourceNode sourceNode = context.createBufferSource();
      sourceNode.connectNode(gainNode);
      sourceNode.buffer = buffer;
      sourceNode.start(0);
    }
    catch (e)
    {
      soundFailed = true;
      trace(e.toString());
    }
  }
}