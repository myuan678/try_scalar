#include <stdio.h>
#include <string.h>

#define ARRAY_SIZE 32
#define GROUP_SIZE 8
#define CELL_WIDTH 15

void input_array(int array[], int size);
void print_separator_line(int group_size, int cell_width);
void print_centered_text(const char* text, int width);
void print_cell(int value, int width);
void print_table(int array[], int array_size, int group_size, int cell_width);


void draw_pic(int numbers[32]) {
    int max_thres = 20;
    int number_input = 32;
    // int max[4];
    int max = numbers[0];
    int length[number_input];
    int max_times=0;

    print_table(numbers, ARRAY_SIZE, GROUP_SIZE, CELL_WIDTH);
    printf("\n");
    int i;
    int j;
    for (i = 0; i < number_input; i++)
    {

        if (numbers[i] > max)
        {
            max = numbers[i];
        }
            
    }

    for (i = 0; i < number_input; i++)
    {
        length[i] = (int)((float)max_thres * numbers[i] / max); 
    }
    printf(" | ----- E N T R Y  0 ----- | ----- E N T R Y  1 ----- | ----- E N T R Y  2 ----- | ----- E N T R Y  3 ----- |\n");
    for (j = max_thres; j >= 0; j--)
    {
        for (i = 0; i < number_input; i++)
        {
            if(i%(number_input/4)==0)
                printf(" | ");
            if (length[i] > j)
                printf(" * ");
            else
                printf("   ");
            if(i==number_input-1)
                printf(" | ");



        }
        printf("\n");
    }

    int line_number;
    for (i = 0; i < number_input; i++)
    {
        if (i % (number_input / 4) == 0){
            printf(" | ");
            line_number = 0;
        }
        printf(" %d ", line_number);
        line_number = line_number + 1;
        if (i == number_input-1)
            printf(" | \n");
        }

}

// int main() {
//     int number[36] = {1, 2, 3, 4, 5, 6, 7, 8,1, 2, 3, 4, 5, 6, 7, 7,1, 2, 3, 4, 5, 6, 6, 6,1, 2, 3, 4, 5, 5, 5, 5,1,2,3,4};
//     draw_pic(number);
//     return 0;
// }


void input_array(int array[], int size) {
    printf("Enter %d integers:\n", size);
    int i;
    for (i = 0; i < size; i++)
    {
        scanf("%d", &array[i]);
    }
}

void print_separator_line(int group_size, int cell_width) {
    printf("+-");
    int j, k;
    for (j = 0; j < group_size + 1; j++)
    {
        for ( k = 0; k < cell_width; k++) {
            printf("-");
        }
        printf("+");
    }
    printf("\n");
}

void print_centered_text(const char* text, int width) {
    int len = strlen(text);
    int pad = (width - len) / 2;
    int i;
    for (i = 0; i < pad; i++)
    {
        printf(" ");
    }
    printf("%s", text);
    for ( i = 0; i < pad; i++) {
        printf(" ");
    }
    if ((width - len) % 2 != 0) {
        printf(" ");
    }
}

void print_cell(int value, int width) {
    char buffer[20];
    sprintf(buffer, "%d", value);
    print_centered_text(buffer, width);
}

void print_table(int array[], int array_size, int group_size, int cell_width) {
    print_separator_line(group_size, cell_width);
    int i, j;
    printf("| ");
    for ( j = 0; j < (group_size+1); j++) {
        char col_title[20];
        if(j==0){
        sprintf(col_title,"", j);
        }
        else if (j==1){
        sprintf(col_title, "fetch empty");

        }
        else{
        sprintf(col_title, "%d", j-1);
        }
        print_centered_text(col_title, cell_width);
        printf("|");
    }
    printf("\n");

    // 输出分隔线
    print_separator_line(group_size, cell_width);

    // 输出数组元素，按每8个数一组
    for ( i = 0; i < array_size; i++) {
        // 每8个数换行，并输出行标题
        if (i % group_size == 0) {
            if (i != 0) {
                print_separator_line(group_size, cell_width);
            }
            char row_title[20];
            sprintf(row_title, "Channel %d", i / group_size);
            printf("| ");
            print_centered_text(row_title, cell_width);
            printf("|");
        }
        print_cell(array[i], cell_width);
        printf("|");

        if ((i + 1) % group_size == 0) {
            printf("\n");
        }
    }
    print_separator_line(group_size, cell_width);
}
