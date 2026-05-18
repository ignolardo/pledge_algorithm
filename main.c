#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>


int maze_height = 7;

#define NO_ROTATE 0
#define RIGHT 1
#define LEFT -1
#define BACK 2

typedef struct Direction {
    int x;
    int y;
} direction;

typedef struct CharacterStats {
    int i;
    int x;
    int y;
    direction dir;
    int angle;
    int rotations;
} char_stats;


void print_all();
void print_info();
void print_maze();
void update_maze();
int find_exit();
//void read_maze_file(const char* filename, char *buffer, int *height);
void read_maze_file(const char* filename, char **p_buffer, int *height);
void init_character_stats();
int pos_to_index(int x, int y);
direction get_direction();
bool is_there_obstacle(char *maze, direction dir);
void rotate_char(int d); // d=1 to rotate clockwise, d=-1 to rotate counter-clockwise
void step_forward();
void init_loop();


char_stats c_stats;

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("Invalid arguments.");
        exit(-1);
    }

    char *maze = malloc(16);

    read_maze_file(argv[1], &maze, &maze_height);

    init_character_stats(maze);

    init_loop(maze);
    free(maze);
    return 0;
}


void init_loop(char *maze) {
    int e = find_exit(maze);
    print_all(maze);

    while (c_stats.i != e) {

        if (c_stats.angle==0 && c_stats.rotations==0) {
            if (!is_there_obstacle(maze, get_direction(c_stats.angle))) { // If not obstacles at front
                rotate_char(NO_ROTATE);
            } else if (!is_there_obstacle(maze, get_direction(c_stats.angle+RIGHT))) { // If not obstacles at right
                rotate_char(RIGHT);
            } else {
                rotate_char(BACK);
            }
        } else {
            /* THE SAME AS ABOVE BUT FIRST LOOK TO THE RIGHT */
            if (!is_there_obstacle(maze, get_direction(c_stats.angle+LEFT))) { // If not obstacles at left
                rotate_char(LEFT);
            } else if (!is_there_obstacle(maze, get_direction(c_stats.angle))) { // If not obstacles at right
                rotate_char(NO_ROTATE);
            } else if (!is_there_obstacle(maze, get_direction(c_stats.angle+RIGHT))) { // If not obstacles at front
                rotate_char(RIGHT);
            } else {
                rotate_char(BACK);
            }
        }

        step_forward(maze);
        
        print_all(maze);
    }

    printf("\nMAZE SOLVED!\n");
}


void step_forward(char *maze) {
    maze[c_stats.i]=' ';
    c_stats.x += c_stats.dir.x;
    c_stats.y += c_stats.dir.y;
    c_stats.i = pos_to_index(c_stats.x, c_stats.y);
    maze[c_stats.i]='X';
}


void rotate_char(int d) {

    c_stats.angle += d;
    c_stats.rotations += d;

    if (c_stats.angle > 3) c_stats.angle -= 4 ;
    else if (c_stats.angle < -3) c_stats.angle += 4 ;

    c_stats.dir = get_direction(c_stats.angle);
}

inline direction get_direction(int angle) {
    switch (angle) {
        case -4: return (direction){.x=1,.y=0}; // right (just for obstacle detection)
        case -3: return (direction){.x=0,.y=1}; // down
        case -2: return (direction){.x=-1,.y=0}; // left
        case -1: return (direction){.x=0,.y=-1}; // up
        case 0: return (direction){.x=1,.y=0}; // right
        case 1: return (direction){.x=0,.y=1}; // down
        case 2: return (direction){.x=-1,.y=0}; // left
        case 3: return (direction){.x=0,.y=-1}; // up
        case 4: return (direction){.x=1,.y=0}; // right (just for obstacle detection)
    }
}

bool is_there_obstacle(char *maze, direction dir) {
    return maze[pos_to_index(c_stats.x + dir.x, c_stats.y + dir.y)]=='M';
}

void init_character_stats(char *maze) {
    for (register int i=0; i<maze_height*16; i++) {
        if (maze[i]=='X') {
            c_stats.i = i;
            c_stats.x = i%16;
            c_stats.y = i/16;
            c_stats.dir = (direction){.x=1,.y=0};
            c_stats.angle = 0;
            c_stats.rotations = 0;
            break;
        }
    }
}


inline int pos_to_index(int x, int y) {
    return y*16+x;
}




inline void print_all(char *maze) {
    print_maze(maze);
    print_info();
}

inline void print_info() {
    printf("i: %d, x: %d, y: %d, angle: %d, rots: %d\n", c_stats.i, c_stats.x, c_stats.y, c_stats.angle, c_stats.rotations);
}


int find_exit(char *maze) {
    for (register int i=0; i<maze_height*16; i++) {
        if (maze[i]=='#') return i;
    }
}


void update_maze(char *maze) {
    for (register int i=0; i<maze_height*16; i++) {
        if (maze[i]=='X') maze[i]==' ';
        if (i==c_stats.i) maze[i]=='X';
    }
}

void print_maze(char *maze) {
    for (register int i=0; i<maze_height*16; i+=16) printf("%.*s\n", 16, maze+i);
}


void read_maze_file(const char* filename, char **p_buffer, int *height) {

    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        printf("\nError al abrir el archivo del laberinto\n");
        exit(-1);
    }

    int maximumLength = 16;

    char ch = getc(file);
    int count = 0;

    while (ch != EOF) {
        if (count == maximumLength) {
            maximumLength += 16;
            *p_buffer = realloc(*p_buffer, maximumLength);
            if (*p_buffer == NULL) {
                printf("Error reallocating space for line buffer.");
                exit(1);
            }
        }

        if (ch == '\n') {
            ch = getc(file);
            continue;
        }

        (*p_buffer)[count] = ch;
        count++;

        ch = getc(file);
    }

    (*p_buffer)[count] = '\0';
    *height = count/16;
}