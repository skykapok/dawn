#ifndef ejoy2d_window_fw_h
#define ejoy2d_window_fw_h

#define WIDTH 1024
#define HEIGHT 768

#define TOUCH_BEGIN 0
#define TOUCH_END 1
#define TOUCH_MOVE 2

#define ORIENT_UP 0
#define ORIENT_DOWN 1
#define ORIENT_LEFT 2
#define ORIENT_RIGHT 3

void ejoy2d_win_init(int orix, int oriy, int width, int height, float scale, const char* folder);
void ejoy2d_win_release();
void ejoy2d_win_frame();
void ejoy2d_win_update(float dt);
void ejoy2d_win_touch(int x, int y,int touch);
void ejoy2d_win_rotate(int width, int height, float scale, int orient);
void ejoy2d_win_resume();

#endif
