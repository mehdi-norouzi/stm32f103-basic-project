#include "stm32f1xx.h"

// Quick and dirty delay
static void delay (unsigned int time) {
    for (unsigned int i = 0; i < time; i++)
        for (volatile unsigned int j = 0; j < 2000; j++);
}

int main (void) {
    // Turn on the GPIOC peripheral
    RCC->APB2ENR |= RCC_APB2ENR_IOPBEN;

    // Put pin 13 in general purpose push-pull mode
    GPIOB->CRH &= ~(GPIO_CRH_CNF14);
    // Set the output mode to max. 2MHz
    GPIOB->CRH |= GPIO_CRH_MODE14_1;

    while (1) {
        // Reset the state of pin 13 to output low
        GPIOB->BSRR = GPIO_BSRR_BR14;

        delay(1000);

        // Set the state of pin 13 to output high
        GPIOB->BSRR = GPIO_BSRR_BS14;

        delay(500);
    }

    // Return 0 to satisfy compiler
    return 0;
}
