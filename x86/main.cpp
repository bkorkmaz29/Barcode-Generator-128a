#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#define TEXT_MAX_LENGTH 100
const char *OUTPUT_FILE_NAME = "output.bmp";

unsigned char header[56] = {66, 77, 200, 95, 1, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 88, 2, 0, 0, 50, 0, 0, 0, 1, 0, 24, 0, 0, 0, 0, 0, 146, 95, 1, 0, 18, 11, 0, 0, 18, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

extern "C" int gen128(unsigned char *bitmap, int bar_width, char *text);
void saveFile(const char *name, unsigned char *buffer);

int main(void)
{
    unsigned char bitmap[90000];
    char text[TEXT_MAX_LENGTH];

    for (int i = 0; i < 90000; i++)
    {
        bitmap[i] = 0xff;
    }

    std::cout << "Input width of the narrowest bar (min: 1, max: 3):" << std::endl;
    int barWidth;
    std::cin >> barWidth;

    std::cout << "Input text to be encoded:" << std::endl;
    std::cin.ignore();
    std::cin.getline(text, TEXT_MAX_LENGTH);

    int result = gen128(bitmap, barWidth, text);

    switch (result)
    {
    case 0:
        saveFile(OUTPUT_FILE_NAME, bitmap);
        break;
    case 1:
        std::cout << "Invalid text" << std::endl;
        break;
    case 2:
        std::cout << "Invalid bar width" << std::endl;
        break;
    }
    return result;
}

void saveFile(const char *name, unsigned char *buffer)
{
    FILE *file;
    file = fopen(name, "wb");
    if (!file)
    {
        std::cerr << "Unable to open file: " << name << std::endl;
        return;
    }

    if (fwrite(header, 54, 1, file) != 1)
    {
        std::cout << "Couldn't write the output header" << std::endl;
        return;
    }

    if (fwrite(buffer, 90000, 1, file) != 1)
    {
        std::cout << "Couldn't write the output pixel buffer" << std::endl;
        return;
    }

    fclose(file);
    std::cout << "Output saved successfully" << std::endl;
}