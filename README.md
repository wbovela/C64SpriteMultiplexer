# C64SpriteMultiplexer

A sprite multiplexer in C64 assembly using C64Studio (ACME style code).

Offer an array of up to 32 unexpanded sprite shapes and coordinates. The multiplexer routine runs after the game code is done and while the frame is built. It maps the 32 sprites onto the 8 available hardware sprites and attempts to draw as many sprites as possible, re-using hardware sprites that have finished drawing. The aim is to not use a sorting routine to work out in which order to draw the sprites. 
