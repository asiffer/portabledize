#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <time.h>
#include <stdlib.h>

#define ROWS 40
#define COLS 80

int main()
{
    char screen[ROWS][COLS + 1];
    int i, j;

    // Initialiser l'écran avec des espaces vides
    for (i = 0; i < ROWS; i++)
    {
        for (j = 0; j < COLS; j++)
        {
            screen[i][j] = ' ';
        }
        screen[i][COLS] = '\0';
    }

    // Générer des caractères aléatoires pour la pluie
    srand(time(NULL));
    for (i = 0; i < COLS; i++)
    {
        screen[0][i] = '0' + (rand() % 2);
    }

    struct timespec ts = {0, 100000000L}; // 100 ms

    while (1)
    {
        // Déplacer la pluie vers le bas
        for (i = ROWS - 1; i > 0; i--)
        {
            for (j = 0; j < COLS; j++)
            {
                screen[i][j] = screen[i - 1][j];
            }
        }

        // Générer une nouvelle ligne de caractères aléatoires
        for (j = 0; j < COLS; j++)
        {
            screen[0][j] = '0' + (rand() % 2);
        }

        // Afficher l'écran
        for (i = 0; i < ROWS; i++)
        {
            printf("\033[32m\033[%d;1H%s\033[0m\n", i + 1, screen[i]);
        }

        nanosleep(&ts, NULL);
    }

    return 0;
}
