library ld37;
import 'dart:html';
import 'dart:math' as Math;
import 'dart:web_audio';
part 'sound.dart';
CanvasRenderingContext2D context;
class Textures
{
  static ImageElement tex_blackhole, tex_enemy, tex_explosion, tex_menu, tex_player, tex_stars;
  static void init()
  {
    tex_blackhole = loadImage("assets/tex/blackhole.png");
    tex_enemy = loadImage("assets/tex/enemy.png");
    tex_explosion = loadImage("assets/tex/explosion.png");
    tex_menu = loadImage("assets/tex/menu.png");
    tex_player = loadImage("assets/tex/player.png");
    tex_stars = loadImage("assets/tex/stars.png");
  }
  static ImageElement loadImage(String path)
  {
    ImageElement img = new ImageElement();
    img.src = path;
    return img;
  }
}
class Enemy
{
  double x, y;
  double w = 32.0, h = 32.0;
  double time = 0.0;
  int phase = 0;
  void reset()
  {
    x = 96.0;
    y = 320.0;
    w = 32.0;
    h = 32.0;
    time = 0.0;
    phase = 0;
  }
  void tick(Game game)
  {
    time++;
    switch (game.level)
    {
      case 12:
        x = -Math.cos(time * 0.02) * 208.0 + 304.0;
        break;
      case 13:
        w = normalizedSin(time * 0.04) * 448.0 + 32.0;
        break;
      case 14:
        x = -Math.cos(time * 0.06) * 208.0 + 304.0;
        y = -Math.sin(time * 0.06) * 192.0 + 320.0;
        break;
      case 15:
        x = -Math.cos(time * 0.025) * 208.0 + 304.0;
        y = -Math.sin(time * 0.05) * 160.0 + 320.0;
        break;
      case 16:
        if (time % 90 == 0) game.addBullet(x, y, 6.0, 0.0);
        break;
      case 17:
        w = normalizedSin(time * 0.03) * 448.0 + 32.0;
        if ((time - 104) % 208 == 0) phase = phase == 1 ? 0 : 1;
        if (phase == 1) x = 576.0 - w;
        h = normalizedSin(time * 0.03) * 64.0 + 32.0;
        y = 336.0 - h / 2.0;
        break;
      case 18:
        double xa = 0.0;
        double ya = 0.0;
        if (phase % 2 == 0) ya = (phase - 1) * 4.0;
        else xa = (phase - 2) * 4.0;
        x += xa;
        y += ya;
        if (time % 70 == 0) game.addBullet(x, y, -ya * 2.0, xa * 2.0);
        if (xa != 0.0 && (x < 96.0 || x > 512.0)) phase--;
        else if (ya != 0 && (y < 80.0 || y > 528.0)) phase--;
        if (phase < 0) phase = 3;
        break;
      case 19:
        if (time % 100 == 0)
        {
          double xa = 0.0;
          double ya = 0.0;
          if (x < 320.0) xa = 6.0;
          else xa = -6.0;
          if (y < 320.0) ya = 6.0;
          else ya = -6.0;
          game.addBullet(x, y, xa, ya);
        }
        double t = normalizedSin(time * 0.008) * 6.0 * Math.PI;
        x = -Math.cos(t) * 208.0 + 304.0;
        y = -Math.sin(t) * 160.0 + 320.0;
        break;
      case 20:
        x = -Math.cos(time * 0.025) * 208.0 + 304.0;
        y = -Math.sin(time * 0.05) * 160.0 + 320.0;
        if (time % 70 == 0) game.addBullet(x, y, x < 320.0 ? 6.0 : -6.0, 0.0);
        break;
      case 21:
        double add = game.winGameTime / 1200.0;
        x = Math.sin(time * (0.03 + add) - Math.PI / 2.0) * 208.0 + 304.0;
        if (time % 90 == 0 || (time - 20) % 90 == 0) game.addBullet(x, y, 0.0, game.player.y < y ? -6.0 : 6.0);
        break;
      default:
        break;
    }
    if (game.player.deadTime >= 0 || game.player.winTime >= 0) return;
    double x0 = game.player.x;
    double y0 = game.player.y;
    double x1 = game.player.x + game.player.w;
    double y1 = game.player.y + game.player.h;
    if (x + w > x0 && x < x1 && y + h > y0 && y < y1) game.die();
  }
}
class Bullet
{
  double x, y, xa, ya;
  Bullet(this.x, this.y, this.xa, this.ya);
  bool tick(Game game)
  {
    x += xa;
    y += ya;
    if (game.player.deadTime >= 0 || game.player.winTime >= 0) return false;
    double x0 = game.player.x;
    double y0 = game.player.y;
    double x1 = game.player.x + game.player.w;
    double y1 = game.player.y + game.player.h;
    if (x + 32.0 > x0 && x < x1 && y + 32.0 > y0 && y < y1) game.die();
    return x < -32 || y < -32 || x > 640 || y > 640;
  }
}
class Player
{
  double x, y, xa, ya;
  double w = 32.0, h = 48.0;
  bool launched = false;
  int deadTime = -1, winTime = -1;
  int frame = 0;
  void reset()
  {
    x = 96.0;
    y = 608.0 - 50.0;
    xa = 0.0;
    ya = 0.0;
    launched = false;
    deadTime = -1;
    winTime = -1;
    frame = 0;
  }
  void tick(Game game)
  {
    if (deadTime >= 0)
    {
      if (deadTime > 0) deadTime--;
      return;
    }
    if (winTime > 0)
    {
      if (--winTime == 0)
      {
        if (game.level < 21) game.nextLevel();
        else
        {
          Sound.snd_wingame.play();
          game.winGameTime = 1;
        }
      }
      return;
    }
    double speed = 0.625;
    if (game.leftDown) xa -= speed;
    if (game.rightDown) xa += speed;
    if (game.boostDown)
    {
      if ((frame & 3) == 0) Sound.snd_rocket.play();
      launched = true;
      ya = -3.25;
      frame++;
    }
    else frame = 0;
    frame &= 7;
    x += xa;
    if (launched && winTime == -1)
    {
      if (!game.isFree(x, y, w, h))
      {
        game.die();
        return;
      }
      y += ya;
      if (y > 700.0 || !game.isFree(x, y, w, h))
      {
        game.die();
        return;
      }
      ya += 0.25;
    }
    else
    {
      if (x < 32.0) x = 32.0;
      else if (x + w > 608.0) x = 608.0 - w;
    }
    xa *= 0.8;
  }
  void render(Game game)
  {
    if (deadTime == -1 && winTime == -1) game.drawTexture(Textures.tex_player, x - 8, y, 48.0, 56.0, (frame >> 1) * 48.0, 0.0);
    else if (deadTime > 0)
    {
      int dt = Math.max(0, deadTime - 80);
      double scale = dt / 10.0;
      if (scale > 0.0) game.drawTextureFrom(Textures.tex_explosion, x + w / 2.0, y + h / 2.0, 0.0, 0.0, 0.0, 0.0, scale, scale);
    }
    else if (winTime > 65)
    {
      double scale = (winTime - 65) / 25.0;
      if (scale > 0.0) game.drawTextureFrom(Textures.tex_player, x + w / 2.0, y + h / 2.0, 48.0, 56.0, 0.0, 0.0, scale, scale);
    }
  }
}
class Game
{
  static const int STATE_TITLE_OPEN = 0;
  static const int STATE_TITLE_CLOSED = 1;
  static const int STATE_GAME = 2;
  static const int STATE_GAME_WON = 3;
  static const int STATE_ABOUT = 4;
  CanvasElement canvas;
  List<bool> tileMap = [
    true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, true, true, true, true, true, true, true, true, true, true, true, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, true, true, true, true, true, true, true, true, true, true, true, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true,
    true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true
  ];
  bool leftDown = false, rightDown = false, boostDown = false;
  int gameState = STATE_TITLE_OPEN;
  int level = 0, instruction = 0, levelTime = 0;
  Player player;
  Enemy enemy;
  double xOffs = 0.0, yOffs = 0.0, xScale = 1.0, yScale = 1.0;
  List<Bullet> bullets = new List<Bullet>();
  int winGameTime = 0;
  Game()
  {
    canvas = document.getElementById("game_canvas");
    context = canvas.getContext("2d");
    context.font = "28px Roboto";
    Textures.init();
    Sound.init();
    window.onKeyDown.listen(onKeyDown);
    window.onKeyUp.listen(onKeyUp);
    canvas.onMouseDown.listen(onMouseDown);
    canvas.onMouseUp.listen(onMouseUp);
    player = new Player();
    enemy = new Enemy();
    window.requestAnimationFrame(animate);
  }
  void animate(double time)
  {
    tick();
    render();
    window.requestAnimationFrame(animate);
  }
  void onKeyDown(KeyboardEvent ke)
  {
    if (ke.keyCode == 65) leftDown = true;
    else if (ke.keyCode == 68) rightDown = true;
  }
  void onKeyUp(KeyboardEvent ke)
  {
    if (ke.keyCode == 65) leftDown = false;
    else if (ke.keyCode == 68) rightDown = false;
  }
  void onMouseDown(MouseEvent me)
  {
    if (gameState == STATE_GAME && instruction == 0 && levelTime == 0) boostDown = true;
  }
  void onMouseUp(MouseEvent me)
  {
    double x = me.offset.x;
    double y = me.offset.y;
    int oldState = gameState;
    switch (gameState)
    {
      case STATE_TITLE_OPEN:
        gameState = STATE_TITLE_CLOSED;
        break;
      case STATE_TITLE_CLOSED:
        if (y > 300.0 && y < 340.0)
        {
          gameState = STATE_GAME;
          nextLevel();
        }
        else if (y > 348.0 && y < 388.0) gameState = STATE_ABOUT;
        break;
      case STATE_GAME:
        if (instruction > 0 && levelTime == 0) instruction = 0;
        if (player.deadTime >= 0 && player.deadTime < 30)
        {
          animTime = 0.0;
          xOffs = 0.0;
          yOffs = 0.0;
          xScale = 1.0;
          yScale = 1.0;
          player.reset();
          enemy.reset();
          bullets.clear();
        }
        boostDown = false;
        break;
      case STATE_ABOUT:
        if (x < 112.0 && y > 600.0) gameState = STATE_TITLE_CLOSED;
        break;
    }
    if (gameState != oldState) Sound.snd_switch.play();
  }
  double time = 0.0, animTime = 0.0;
  void tick()
  {
    if (winGameTime > 0)
    {
      winGameTime++;
      if (gameState == STATE_GAME && winGameTime == 240)
      {
        Sound.snd_explosion.play();
        gameState = STATE_GAME_WON;
        winGameTime = 1;
      }
      if (winGameTime == 500)
      {
        gameState = STATE_TITLE_OPEN;
        level = 0;
        winGameTime = 0;
      }
    }
    time++;
    if (gameState == STATE_GAME)
    {
      if (levelTime > 0)
      {
        if (--levelTime == 0) Sound.snd_thud.play();
      }
      else if (instruction == 0)
      {
        animTime++;
        switch (level)
        {
          case 2:
            xScale = normalizedSin(animTime * 0.03) * 0.5 + 1.0;
            break;
          case 3:
            yScale = normalizedSin(animTime * 0.03) * 0.5 + 1.0;
            break;
          case 4:
            double scale = normalizedSin(animTime * 0.05) * 0.6 + 1.0;
            double mod = 2 * Math.PI / 0.05;
            if ((animTime / mod).floor() % 2 == 0) xScale = scale;
            else yScale = scale;
            break;
          case 5:
            xScale = 1.0 - normalizedSin(animTime * 0.03) * 0.5;
            break;
          case 6:
            yScale = normalizedSin(animTime * 0.015 - 1.36) + 0.6;
            break;
          case 7:
            xOffs = -Math.sin(animTime * 0.02) * 160.0;
            break;
          case 8:
            xOffs = Math.sin(animTime * 0.015) * 160.0;
            xScale = 1.0 - normalizedSin(animTime * 0.03) * 0.5;
            break;
          case 9:
            xOffs = (1.0 - Math.cos(animTime * 0.03)) * 80.0;
            yOffs = Math.sin(animTime * 0.03) * 80.0;
            break;
          case 10:
            xOffs = (Math.cos(animTime * 0.02) - 1.0) * 160.0;
            yOffs = Math.sin(animTime * 0.02) * 80.0;
            xScale = normalizedSin(animTime * 0.02) + 1.0;
            break;
          case 11:
            xOffs = Math.sin(animTime * 0.015) * 120.0;
            yOffs = Math.sin(animTime * 0.03) * 80.0;
            xScale = (1.0 - normalizedSin(animTime * 0.01)) * 0.2 + 0.8;
            yScale = normalizedSin(animTime * 0.02) * 0.5 + 1.0;
            break;
          case 15:
            xScale = normalizedSin(animTime * 0.03 - 1.36) + 0.6;
            break;
          case 16:
            yScale = normalizedSin(animTime * 0.02 - 1.36) + 0.6;
            yOffs = 320.0 * yScale - 320.0;
            break;
          case 17:
            yOffs = Math.sin(animTime * 0.015) * 100.0;
            yScale = normalizedSin(animTime * 0.025 - 1.16) + 0.7;
            break;
          case 18:
            xScale = 0.8 + normalizedSin(animTime * 0.03) * 0.5;
            yScale = 0.8 + normalizedSin(animTime * 0.03 - Math.PI / 2.0) * 0.5;
            break;
          case 19:
            double t = normalizedSin(animTime * 0.004) * 6.0 * Math.PI;
            xOffs = Math.sin(t) * 80.0;
            yOffs = (1.0 - Math.cos(t)) * 80.0;
            break;
          case 20:
            xOffs = Math.cos(animTime * 0.03) * 80.0;
            yOffs = Math.sin(animTime * 0.03) * 80.0;
            xScale = 0.6 + normalizedSin(animTime * 0.02) * 0.8;
            yScale = 1.0 + normalizedSin(animTime * 0.02 - Math.PI / 2.0) * 0.6;
            break;
          case 21:
            double add = winGameTime / 1200.0;
            xOffs = Math.sin(animTime * (0.05 + add)) * 60.0;
            yOffs = Math.sin(animTime * (0.025 + add)) * 60.0;
            double scale = normalizedSin(animTime * (0.06 + add)) * 0.6 + 1.0;
            double mod = 2 * Math.PI / (0.06 + add);
            if ((animTime / mod).floor() % 2 == 0) xScale = scale;
            else yScale = scale;
            break;
          default:
            break;
        }
        player.tick(this);
        enemy.tick(this);
        for (int i = 0; i < bullets.length; i++)
        {
          if (bullets[i].tick(this)) bullets.removeAt(i--);
        }
        if (player.winTime == -1)
        {
          double x0 = (512.0 - 320.0) * xScale + 320.0 + xOffs;
          double y0 = (96.0 - 320.0) * yScale + 320.0 + yOffs;
          double x1 = (544.0 - 320.0) * xScale + 320.0 + xOffs;
          double y1 = (128.0 - 320.0) * yScale + 320.0 + yOffs;
          context.fillStyle = "#00ff00";
          context.fillRect(x0, y0, x1 - x0, y1 - y0);
          if (player.x + player.w > x0 && player.x < x1 && player.y + player.h > y0 && player.y < y1)
          {
            boostDown = false;
            Sound.snd_win.play();
            player.winTime = 90;
          }
        }
      }
    }
  }
  void nextLevel()
  {
    level++;
    player.reset();
    enemy.reset();
    bullets.clear();
    animTime = 0.0;
    levelTime = 100;
    xOffs = 0.0;
    yOffs = 0.0;
    xScale = 1.0;
    yScale = 1.0;
    if (level == 1) instruction = 1;
    else if (level == 2) instruction = 2;
    else if (level == 3) instruction = 3;
    else if (level == 7) instruction = 4;
    else if (level == 12) instruction = 5;
    else if (level == 15) instruction = 6;
    else if (level == 21) instruction = 7;
  }
  void die()
  {
    Sound.snd_explosion.play();
    player.deadTime = 90;
  }
  void addBullet(double x, double y, double xa, double ya)
  {
    Sound.snd_laser.play();
    bullets.add(new Bullet(x, y, xa, ya));
  }
  bool isFree(double xc, double yc, double w, double h)
  {
    double xMin = 320.0 - 320.0 / xScale;
    double yMin = 320.0 - 320.0 / yScale;
    double xMax = 320.0 + 320.0 / xScale;
    double yMax = 320.0 + 320.0 / yScale;
    xc = (xc - xOffs) / 640.0 * (xMax - xMin) + xMin;
    yc = (yc - yOffs) / 640.0 * (yMax - yMin) + yMin;
    w /= xScale;
    h /= yScale;
    double e = 0.1;
    int x0 = (xc / 32.0).floor();
    int y0 = (yc / 32.0).floor();
    int x1 = ((xc + w - e) / 32.0).floor();
    int y1 = ((yc + h - e) / 32.0).floor();
    for (int y = y0; y <= y1; y++)
    {
      for (int x = x0; x <= x1; x++)
      {
        if (x >= 0 && y >= 0 && x < 20 && y < 20)
        {
          if (tileMap[x + y * 20]) return false;
        }
      }
    }
    return true;
  }
  void render()
  {
    context.fillStyle = "#000000";
    context.fillRect(0, 0, canvas.width, canvas.height);
    switch (gameState)
    {
      case STATE_TITLE_OPEN:
      case STATE_TITLE_CLOSED:
        renderTitle(gameState == STATE_TITLE_CLOSED);
        break;
      case STATE_GAME:
        renderGame();
        break;
      case STATE_GAME_WON:
        double width = 640.0 - winGameTime * 5.0;
        if (width > 0)
        {
          context.fillStyle = "#00ccff";
          context.fillRect(320.0 - width / 2.0, 318.0, width, 4.0);
        }
        if (winGameTime > 200)
        {
          String msg = "I think you broke the universe.";
          int end = (winGameTime ~/ 2) - 100;
          if (end < msg.length) msg = msg.substring(0, end);
          drawShadowString(msg, 132, 300);
        }
        break;
      case STATE_ABOUT:
        drawTexture(Textures.tex_stars, -(time % 640), 0.0);
        drawTexture(Textures.tex_stars, -(time % 640) + 640.0, 0.0);
        drawTexture(Textures.tex_menu, 8.0, 0.0, 244.15, 58.0, 0.0, 420.0);
        drawShadowString("This game was made by Craig Horwood over the", 8, 80);
        drawShadowString("course of 48 hours for Ludum Dare 37. But I'm", 8, 110);
        drawShadowString("sure you knew that.", 8, 140);
        drawShadowString("What I bet you didn't know is that I finished this", 8, 200);
        drawShadowString("game on December 12th, one day AFTER the", 8, 230);
        drawShadowString("competition ended. That can mean one of two", 8, 260);
        drawShadowString("things: either that I'm a time-travelling cheater, or", 8, 290);
        drawShadowString("that I'm Australian.", 8, 320);
        drawShadowString("This game was programmed, and not all that well,", 8, 380);
        drawShadowString("in Dart. If you insist on seeing the source code, I've", 8, 410);
        drawShadowString("attached a ZIP file below. Mostly I'd rather you just", 8, 440);
        drawShadowString("play the game.", 8, 470);
        drawTexture(Textures.tex_menu, 8.0, 600.0, 112.0, 40.0, 0.0, 380.0);
        break;
    }
  }
  void renderTitle(bool isClosed)
  {
    drawTexture(Textures.tex_stars, -(time % 640), 0.0);
    drawTexture(Textures.tex_stars, -(time % 640) + 640.0, 0.0);
    if (!isClosed)
    {
      double t = time * 0.04;
      double xs = (Math.sin(t) * 0.5) + 1.5;
      double ys = (Math.cos(t) * 0.5) + 1.5;
      drawTextureFrom(Textures.tex_menu, 320.0, 148.0, 328.0, 168.0, 0.0, 0.0, xs, ys);
      drawTextureFrom(Textures.tex_menu, 320.0, 380.0, 343.0, 40.0, 0.0, 180.0, Math.sin(t * 0.75) * 0.5 + 1.0, 1.0);
    }
    else
    {
      drawTexture(Textures.tex_menu, 156.0, 64.0, 328.0, 168.0, 0.0, 0.0);
      drawTexture(Textures.tex_menu, 183.0, 300.0, 274.0, 40.0, 0.0, 220.0);
      drawTexture(Textures.tex_menu, 244.6, 348.0, 150.8, 40.0, 0.0, 260.0);
    }
  }
  void renderGame()
  {
    drawTexture(Textures.tex_stars, 0.0, 0.0);
    double pr = Math.sin(time / 16.0) / 2.0 + 0.5;
    int r = (0.0 + pr * 182.0).floor();
    int g = (204.0 + pr * (240.0 - 204.0)).floor();
    context.fillStyle = "rgb(" + r.toString() + ", " + g.toString() + ", 255)";
    double wTile = 32.0 * xScale;
    double hTile = 32.0 * yScale;
    double xBuf = 320.0 * xScale;
    double yBuf = 320.0 * yScale;
    drawLevel(0, 0, 640, 32);
    drawLevel(0, 608, 640, 32);
    drawLevel(0, 0, 32, 640);
    drawLevel(608, 0, 32, 640);
    drawLevel(0, 416, 384, 32);
    drawLevel(256, 192, 384, 32);
    drawRotatedTexture(Textures.tex_blackhole, 16.5 * wTile + 320.0 - xBuf + xOffs, 3.5 * hTile + 320.0 - yBuf + yOffs, xScale, yScale, time / 32.0);
    player.render(this);
    for (int i = 0; i < bullets.length; i++)
    {
      Bullet b = bullets[i];
      drawDiamond(b.x, b.y, 32.0, 32.0);
    }
    drawDiamond(enemy.x, enemy.y, enemy.w, enemy.h);
    int xMsg = 0;
    int yMsg = 0;
    if (levelTime > 50)
    {
      xMsg = 280;
      yMsg = 300;
    }
    else if (levelTime > 0)
    {
      xMsg = (levelTime / 50.0 * 280.0).floor();
      yMsg = (levelTime / 50.0 * 300.0).floor();
    }
    drawShadowString("LEVEL " + level.toString(), xMsg, yMsg);
    if (levelTime == 0)
    {
      if (instruction > 0)
      {
        context.fillStyle = "#444444";
        context.fillRect(120, 120, 400, 400);
        context.fillStyle = "#666666";
        context.fillRect(136, 136, 400 - 32, 400 - 32);
        drawTexture(Textures.tex_menu, 166.5, 144.0, 307.0, 40.0, 0.0, 300.0);
      }
      switch (instruction)
      {
      case 1:
        drawShadowString("- Guide the rocket to the", 144, 200);
        drawShadowString("black hole.", 144, 226);
        drawShadowString("- Move left and right with the", 144, 270);
        drawShadowString("A and D keys.", 144, 296);
        drawShadowString("- Hold the left mouse button", 144, 340);
        drawShadowString("to boost upwards.", 144, 366);
        drawShadowString("- Once you have launched,", 144, 410);
        drawShadowString("you cannot touch anything!", 144, 436);
        break;
      case 2:
        drawShadowString("- The black hole has sent", 144, 200);
        drawShadowString("you to the beginning of the", 144, 226);
        drawShadowString("level.", 144, 252);
        drawShadowString("- It has also caused a minor", 144, 296);
        drawShadowString("disturbance in the space-", 144, 322);
        drawShadowString("time continuum.", 144, 348);
        drawShadowString("- As such, space will behave", 144, 392);
        drawShadowString("differently each time you", 144, 418);
        drawShadowString("enter the black hole.", 144, 444);
        break;
      case 3:
        drawShadowString("- Do not be alarmed if the", 144, 200);
        drawShadowString("floor beneath you starts to", 144, 226);
        drawShadowString("pull away.", 144, 252);
        drawShadowString("- Remember that you are", 144, 296);
        drawShadowString("only vulnerable once you", 144, 322);
        drawShadowString("take off.", 144, 348);
        drawShadowString("- I think you're good on your", 144, 392);
        drawShadowString("own for a little while.", 144, 418);
        break;
      case 4:
        drawShadowString("- Sometimes, instead of", 144, 200);
        drawShadowString("dilating, space will simply", 144, 226);
        drawShadowString("shift position relative to you.", 144, 252);
        drawShadowString("- I know, it's annoying.", 144, 296);
        drawShadowString("Relativity is like that.", 144, 322);
        drawShadowString("- But remember, you chose", 144, 366);
        drawShadowString("this career. Always expect", 144, 392);
        drawShadowString("the unexpected.", 144, 418);
        break;
      case 5:
        drawShadowString("- Whew! Finally, space is", 144, 200);
        drawShadowString("stable again! No more", 144, 226);
        drawShadowString("moving walls! ...For now.", 144, 252);
        drawShadowString("- Anyway, did you ever notice", 144, 296);
        drawShadowString("that blue diamond?", 144, 322);
        drawShadowString("- I guess since we've been", 144, 366);
        drawShadowString("rupturing the fabric of reality,", 144, 392);
        drawShadowString("it might start doing", 144, 418);
        drawShadowString("something now...", 144, 444);
        break;
      case 6:
        drawShadowString("- We must have taken a", 144, 200);
        drawShadowString("wrong turn! Space-time has", 144, 226);
        drawShadowString("destabilised again!", 144, 252);
        drawShadowString("- And now you've got the", 144, 296);
        drawShadowString("diamond to deal with too!", 144, 322);
        break;
      case 7:
        drawShadowString("- You're almost to the end!", 144, 200);
        drawShadowString("Space-time is getting pretty", 144, 226);
        drawShadowString("crazy now!", 144, 252);
        drawShadowString("- If you manage to survive", 144, 296);
        drawShadowString("this next warping of reality,", 144, 322);
        drawShadowString("I will be legitimately", 144, 348);
        drawShadowString("impressed.", 144, 374);
        break;
      default:
        break;
      }
      if (player.deadTime >= 0 && player.deadTime < 30)
      {
        context.fillStyle = "#444444";
        context.fillRect(80, 288, 480, 64);
        context.fillStyle = "#666666";
        context.fillRect(80 + 8, 288 + 8, 480 - 16, 64 - 16);
        drawTexture(Textures.tex_menu, 118.5, 288.0 + 16.0, 403.0, 40.0, 0.0, 340.0);
      }
    }
  }
  void drawTexture(ImageElement tex, double x, double y, [double w = 0.0, double h = 0.0, double uo = 0.0, double vo = 0.0, double xs = 1.0, double ys = 1.0])
  {
    if (w == 0.0) w = tex.width * 1.0;
    if (h == 0.0) h = tex.height * 1.0;
    context.drawImageScaledFromSource(tex, uo, vo, w, h, x, y, w * xs, h * ys);
  }
  void drawTextureFrom(ImageElement tex, double xo, double yo, double w, double h, double uo, double vo, double xs, double ys)
  {
    if (w == 0.0) w = tex.width * 1.0;
    if (h == 0.0) h = tex.height * 1.0;
    double x = xo - w / 2.0 * xs;
    double y = yo - h / 2.0 * ys;
    drawTexture(tex, x, y, w, h, uo, vo, xs, ys);
  }
  void drawRotatedTexture(ImageElement tex, double x, double y, double xs, double ys, double rot)
  {
    context.save();
    context.translate(x, y);
    context.rotate(rot);
    context.translate(-x, -y);
    drawTexture(tex, x - xs * 24.0, y - ys * 24.0, 0.0, 0.0, 0.0, 0.0, xs, ys);
    context.restore();
  }
  void drawShadowString(String msg, int x, int y)
  {
    context.fillStyle = "#000000";
    context.fillText(msg, x + 2, y + 2 + 24);
    context.fillStyle = "#ffffff";
    context.fillText(msg, x, y + 24);
  }
  void drawLevel(int x, int y, int w, int h)
  {
    double x0 = x * 1.0;
    double y0 = y * 1.0;
    double x1 = x0 + w;
    double y1 = y0 + h;
    x0 = (x0 - 320.0) * xScale + 320.0;
    y0 = (y0 - 320.0) * yScale + 320.0;
    x1 = (x1 - 320.0) * xScale + 320.0;
    y1 = (y1 - 320.0) * yScale + 320.0;
    x0 += xOffs;
    y0 += yOffs;
    x1 += xOffs;
    y1 += yOffs;
    context.fillRect(x0, y0, x1 - x0, y1 - y0);
  }
  void drawDiamond(double x, double y, double w, double h)
  {
    context.fillStyle = "#4762ff";
    context.beginPath();
    context.moveTo(x, y + h / 2.0);
    context.lineTo(x + w / 2.0, y);
    context.lineTo(x + w, y + h / 2.0);
    context.lineTo(x + w / 2.0, y + h);
    context.fill();
  }
}
void main()
{
  try
  {
    new Game();
  }
  catch (e)
  {
    trace(e.toString());
  }
}
double normalizedSin(double x)
{
  return 0.5 - Math.cos(x) * 0.5;
}
void trace(String msg)
{
  querySelector("#debug").setInnerHtml(msg);
}