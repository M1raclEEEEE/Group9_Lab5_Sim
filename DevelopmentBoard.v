#include <verilated.h>
#include <GL/glut.h>
#include <thread>
#include <iostream>
#include <atomic>
#include <string>

#include "VDevelopmentBoard.h"

using namespace std;


void wait_10ns();
void graphics_loop(int argc, char** argv);
void apply_input();
void update_leds();
void tick();
void reset();
void sample_pixel();
void update_state_display();
void render(void);
void glutTimer(int t);
void keyPressed(unsigned char key, int x, int y);
void keyReleased(unsigned char key, int x, int y);
void drawCircle(float cx, float cy, float r, int num_segments);


VDevelopmentBoard* display;
uint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

bool gl_setup_complete = false;


const int LEFT_PORCH = 48;
const int ACTIVE_WIDTH = 640;
const int RIGHT_PORCH = 16;
const int HORIZONTAL_SYNC = 96;
const int TOTAL_WIDTH = 800;

const int TOP_PORCH = 33;
const int ACTIVE_HEIGHT = 480;
const int BOTTOM_PORCH = 10;
const int VERTICAL_SYNC = 2;
const int TOTAL_HEIGHT = 525;

const int H_ACTIVE_START = 144;
const int V_ACTIVE_START = 35;


float graphics_buffer[ACTIVE_WIDTH][ACTIVE_HEIGHT][3] = {};

float pixel_w = 2.0 / ACTIVE_WIDTH * 0.8f;
float pixel_h = 2.0 / ACTIVE_HEIGHT * 0.8f;

bool restart_triggered = false;
std::atomic<int> leds_state[5] = {1, 1, 1, 1, 1};
std::string current_state = "COLOR_BAR";

const int WINDOW_WIDTH = 800;
const int WINDOW_HEIGHT = 600;


void wait_10ns() {
    for (volatile int i = 0; i < 100; ++i) {}
}

void drawCircle(float cx, float cy, float r, int num_segments) {
    glBegin(GL_TRIANGLE_FAN);
    for(int i = 0; i < num_segments; i++) {
        float theta = 2.0f * 3.1415926f * float(i) / float(num_segments);
        glVertex2f(r * cosf(theta) + cx, r * sinf(theta) + cy);
    }
    glEnd();
}


void update_state_display() {
   
    if (leds_state[2] == 0) {
        current_state = "FUN BREAKOUT";
    } else if (leds_state[3] == 0) {
        current_state = "BREAKOUT GAME";
    } else if (leds_state[4] == 0) {
        current_state = "END";
    } else {
        current_state = "FUN BREAKOUT";
    }
}


void render(void) {
    glClear(GL_COLOR_BUFFER_BIT);

    
    glColor3f(0.1f, 0.1f, 0.1f);
    glRectf(-1.0f, -1.0f, 1.0f, 1.0f);

  
    glColor3f(1.0f, 1.0f, 1.0f);
    glRasterPos2f(-0.9f, 0.9f);
    for (char c : "VGA Display - Breakout Game (Fast Version)") {
        glutBitmapCharacter(GLUT_BITMAP_9_BY_15, c);
    }
    
    glRasterPos2f(-0.9f, 0.8f);
    std::string state_text = "Current State: " + current_state;
    for (char c : state_text) {
        glutBitmapCharacter(GLUT_BITMAP_9_BY_15, c);
    }

  
    if (current_state == "BREAKOUT GAME") {
        glRasterPos2f(-0.9f, 0.7f);
        for (char c : "Use 'D' and 'F' keys to control the paddle!") {
            glutBitmapCharacter(GLUT_BITMAP_9_BY_15, c);
        }
    }

  
    for(int i = 0; i < ACTIVE_WIDTH; i++){
        for(int j = 0; j < ACTIVE_HEIGHT; j++){
            glColor3f(graphics_buffer[i][j][0], graphics_buffer[i][j][1], graphics_buffer[i][j][2]);
            float x1 = (i * pixel_w - 0.8f) * 0.8f;
            float y1 = (-j * pixel_h + 0.6f) * 0.8f + 0.3f;
            float x2 = ((i+1) * pixel_w - 0.8f) * 0.8f;
            float y2 = (-(j+1) * pixel_h + 0.6f) * 0.8f + 0.3f;
            glRectf(x1, y1, x2, y2);
        }
    }

  
    glColor3f(0.2f, 0.2f, 0.2f);
    glRectf(-1.0f, -1.0f, 1.0f, -0.7f);
    
    glColor3f(1.0f, 1.0f, 1.0f);
    glRasterPos2f(-0.9f, -0.75f);
    for (char c : "Press 's' to switch states, 'a' to reset, 'd'=left, 'f'=right") {
        glutBitmapCharacter(GLUT_BITMAP_9_BY_15, c);
    }

    glRasterPos2f(-0.9f, -0.85f);
    for (char c : "LED Indicators: S(System) B(Button) C(Breakout) E(End)") {
        glutBitmapCharacter(GLUT_BITMAP_9_BY_15, c);
    }

 
    float led_spacing = 1.6f / 6.0f;
    float led_radius = 0.04f;
    for(int i = 0; i < 5; i++){
        float x_pos = -0.8f + (i+1) * led_spacing;
        float y_pos = -0.95f;
        
        glColor3f(0.3f, 0.3f, 0.3f);
        drawCircle(x_pos, y_pos, led_radius * 1.2f, 20);
        
      
        if (i == 0) {
            glColor3f(leds_state[i] ? 0.1f : 0.0f, leds_state[i] ? 0.1f : 1.0f, 0.0f);
        } else if (i == 1) {
            glColor3f(leds_state[i] ? 0.1f : 1.0f, leds_state[i] ? 0.1f : 1.0f, 0.0f);
        } else {
            glColor3f(leds_state[i] ? 0.1f : 1.0f, 0.0f, 0.0f);
        }
        drawCircle(x_pos, y_pos, led_radius, 20);
        
        glColor3f(1.0f, 1.0f, 1.0f);
        glRasterPos2f(x_pos - 0.01f, y_pos - 0.06f);
        if (i == 0) {
            glutBitmapCharacter(GLUT_BITMAP_9_BY_15, 'S');
        } else if (i == 1) {
            glutBitmapCharacter(GLUT_BITMAP_9_BY_15, 'B');
        } else if (i == 2) {
            glutBitmapCharacter(GLUT_BITMAP_9_BY_15, 'C');
        } else if (i == 3) {
            glutBitmapCharacter(GLUT_BITMAP_9_BY_15, 'G');
        } else {
            glutBitmapCharacter(GLUT_BITMAP_9_BY_15, 'E');
        }
    }
    
    glFlush();
}


void glutTimer(int t) {
    glutPostRedisplay();
    glutTimerFunc(t, glutTimer, t);
}


std::atomic<int> keys[5] = {1, 1, 1, 1, 1};
void keyPressed(unsigned char key, int x, int y) {
    switch(key) {
        case 'a': keys[0] = 0; restart_triggered = true; break;
        case 's': keys[1] = 0; break;
        case 'd': keys[2] = 0; break; 
        case 'f': keys[3] = 0; break;  
        case 'g': keys[4] = 0; break;
    }
}

void keyReleased(unsigned char key, int x, int y) {
    switch(key) {
        case 'a': keys[0] = 1; break;
        case 's': keys[1] = 1; break;
        case 'd': keys[2] = 1; break;  
        case 'f': keys[3] = 1; break;  
        case 'g': keys[4] = 1; break;
    }
}


void graphics_loop(int argc, char** argv) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_SINGLE);
    glutInitWindowSize(WINDOW_WIDTH, WINDOW_HEIGHT);
    glutInitWindowPosition(100, 100);
    glutCreateWindow("VGA Simulator - Breakout Game (Fast Version)");
    glutDisplayFunc(render);
    glutSetKeyRepeat(GLUT_KEY_REPEAT_OFF);
    glutKeyboardFunc(keyPressed);
    glutKeyboardUpFunc(keyReleased);
    
    gl_setup_complete = true;
    glutTimerFunc(16, glutTimer, 16);
    glutMainLoop();
}


int coord_x = 0, coord_y = 0;
bool pre_h_sync = 0, pre_v_sync = 0;


void apply_input() {
    display->reset = keys[0];
    display->B2 = keys[1];
    display->B3 = keys[2];  
    display->B4 = keys[3];  
    display->B5 = keys[4];
}


void update_leds() {
    leds_state[0] = display->led1;
    leds_state[1] = display->led2;
    leds_state[2] = display->led3;
    leds_state[3] = display->led4;
    leds_state[4] = display->led5;
}


void tick() {
    wait_10ns();
    main_time++;
    display->clk = 1;
    apply_input();
    display->eval();
    update_leds();
    
    wait_10ns();
    main_time++;
    display->clk = 0;
    display->eval();
}


void reset() {
    display->reset = 0;
    display->B2 = display->B3 = display->B4 = display->B5 = 1;
    display->clk = 0;
    display->eval();
    
  
    for(int i = 0; i < 10; i++) tick();
    display->reset = 1;
    
   
    for(int i = 0; i < ACTIVE_WIDTH; i++)
        for(int j = 0; j < ACTIVE_HEIGHT; j++)
            graphics_buffer[i][j][0] = graphics_buffer[i][j][1] = graphics_buffer[i][j][2] = 0.0f;
    
   
    coord_x = coord_y = 0;
    pre_h_sync = pre_v_sync = 0;
    restart_triggered = false;
}


void sample_pixel() {
    coord_x = (coord_x + 1) % TOTAL_WIDTH;

 
    if(display->h_sync && !pre_h_sync) {
        coord_x = 0;
        coord_y = (coord_y + 1) % TOTAL_HEIGHT;
    }

  
    if(display->v_sync && !pre_v_sync) {
        coord_y = 0;
    }

  
    if(coord_x >= H_ACTIVE_START && coord_x < H_ACTIVE_START + ACTIVE_WIDTH && 
       coord_y >= V_ACTIVE_START && coord_y < V_ACTIVE_START + ACTIVE_HEIGHT) {
        int x = coord_x - H_ACTIVE_START;
        int y = coord_y - V_ACTIVE_START;
        int rgb = display->rgb;
        
      
        graphics_buffer[x][y][0] = float((rgb & 0xF800) >> 11) / 31.0f;
        graphics_buffer[x][y][1] = float((rgb & 0x07E0) >> 5) / 63.0f;
        graphics_buffer[x][y][2] = float(rgb & 0x001F) / 31.0f;
    }

    pre_h_sync = display->h_sync;
    pre_v_sync = display->v_sync;
}

int main(int argc, char** argv) {
  
    thread graphics_thread(graphics_loop, argc, argv);
    while(!gl_setup_complete);

    Verilated::commandArgs(argc, argv);
    display = new VDevelopmentBoard;
    reset();

    while (!Verilated::gotFinish()) {
        if (restart_triggered) reset();
        tick();
        tick();
        sample_pixel();
        update_state_display();
    }

    display->final();
    delete display;
    graphics_thread.join();
    return 0;
}
