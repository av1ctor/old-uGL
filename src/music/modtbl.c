/*
**
** src/modtbl.c - Tables used for playback
**
**
*/
#include "inc/modcmn.h"


//
// Protracker sorted period table
// Indexed as note*8 + finetune where -8 <= finetune <= 7 
// and the 0 <= note <= 35. C-1 is index 0, B-3 is 35
//
/*
uint16 PTPeriodTable[288] = { 856, 850, 844, 838, 832, 826, 820, 814,
                              808, 802, 796, 791, 785, 779, 774, 768,
                              762, 757, 752, 746, 741, 736, 730, 725,
                              720, 715, 709, 704, 699, 694, 689, 684,
                              678, 675, 670, 665, 660, 655, 651, 646,
                              640, 636, 632, 628, 623, 619, 614, 610,
                              604, 601, 597, 592, 588, 584, 580, 575,
                              570, 567, 563, 559, 555, 551, 547, 543,
                              538, 535, 532, 528, 524, 520, 516, 513,
                              508, 505, 502, 498, 494, 491, 487, 484,
                              480, 477, 474, 470, 467, 463, 460, 457,
                              453, 450, 447, 444, 441, 437, 434, 431,
                              428, 425, 422, 419, 416, 413, 410, 407,
                              404, 401, 398, 395, 392, 390, 387, 384,
                              381, 379, 376, 373, 370, 368, 365, 363,
                              360, 357, 355, 352, 350, 347, 345, 342,
                              339, 337, 335, 332, 330, 328, 325, 323,
                              320, 318, 316, 314, 312, 309, 307, 305,
                              302, 300, 298, 296, 294, 292, 290, 288,
                              285, 284, 282, 280, 278, 276, 274, 272,
                              269, 268, 266, 264, 262, 260, 258, 256,
                              254, 253, 251, 249, 247, 245, 244, 242,
                              240, 238, 237, 235, 233, 232, 230, 228,
                              226, 225, 223, 222, 220, 219, 217, 216,
                              214, 212, 211, 209, 208, 206, 205, 203,
                              202, 200, 199, 198, 196, 195, 193, 192,
                              190, 189, 188, 187, 185, 184, 183, 181,
                              180, 179, 177, 176, 175, 174, 172, 171,
                              170, 169, 167, 166, 165, 164, 163, 161,
                              160, 159, 158, 157, 156, 155, 154, 152,
                              151, 150, 149, 148, 147, 146, 145, 144,
                              143, 142, 141, 140, 139, 138, 137, 136,
                              135, 134, 133, 132, 131, 130, 129, 128,
                              127, 126, 125, 125, 123, 123, 122, 121,
                              120, 119, 118, 118, 117, 116, 115, 114,
                              113, 113, 112, 111, 110, 109, 109, 108 };
*/

uint16 S3MPeriodTable[12*11] = { 27392, 25856, 24384, 23040, 21696, 20480, 
                                 19328, 18240, 17216, 16256, 15360, 14496 };

uint16 S3MFinetuneTable[16] = { 8363, 8413, 8463, 8529, 8581, 8651, 8723, 8757, 
                                7895, 7941, 7985, 8046, 8107, 8169, 8232, 8280 };


                                
//
// Protracker sine table, used for effects
//
//
uint16 sineTable[32] = {   0,  24,  49,  74,  97, 120, 141, 161,
	                     180, 197, 212, 224, 235, 244, 250, 253,
	                     255, 253, 250, 244, 235, 224, 212, 197,
	                     180, 161, 141, 120,  97,  74,  49,  24 };
