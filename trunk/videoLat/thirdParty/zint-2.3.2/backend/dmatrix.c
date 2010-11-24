/* dmatrix.c - Handles Data Matrix 2-D symbology */

/*
    libzint - the open source barcode library
    Copyright (C) 2008 Robin Stuart <robin@zint.org.uk>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include <string.h>
#include <stdio.h>
#ifdef _MSC_VER
#include <malloc.h> 
#endif
#include "dmatrix.h"
#include "common.h"
#ifdef __cplusplus
#include "dm200.h"
#else
extern int data_matrix_200(struct zint_symbol *symbol, unsigned char source[], int length);
#endif

#define SODIUM " 0123456789"
#define COBALT " ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define RUBIDIUM " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
#define NIOBIUM " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,-/"

void crc_machine(char data_prefix_bitstream[], int scheme, unsigned char source[], int length)
{
	int input_length, i, debug = 0;
	char xor_register[17];
	int machine_cycles;
	char input_bit, out1, out2, out3;
#ifdef _MSC_VER
	char* precrc_bitstream;
	char* precrc_bitstream_reversed;
#endif
	input_length = length;

#ifndef _MSC_VER
	char precrc_bitstream[(input_length * 8) + 18];
	char precrc_bitstream_reversed[(input_length * 8) + 18];
#else
	precrc_bitstream = (char*)_alloca((input_length * 8) + 18);
	precrc_bitstream_reversed = (char*)_alloca((input_length * 8) + 18);
#endif

	switch(scheme) {
		case 11: strcpy(precrc_bitstream, "0000000100000000"); if(debug) { printf("Scheme 11\n"); } break;
		case 27: strcpy(precrc_bitstream, "0000001000000000"); if(debug) { printf("Scheme 27\n"); } break;
		case 41: strcpy(precrc_bitstream, "0000001100000000"); if(debug) { printf("Scheme 41\n"); } break;
		case 37: strcpy(precrc_bitstream, "0000010000000000"); if(debug) { printf("Scheme 37\n"); } break;
		default: strcpy(precrc_bitstream, "0000010100000000"); if(debug) { printf("Scheme DE\n"); } break;
	}
	
	for(i = 0; i < input_length; i++) {
		if(source[i] & 0x80) { concat(precrc_bitstream, "1"); } else { concat(precrc_bitstream, "0"); }
		if(source[i] & 0x40) { concat(precrc_bitstream, "1"); } else { concat(precrc_bitstream, "0"); }
		if(source[i] & 0x20) { concat(precrc_bitstream, "1"); } else { concat(precrc_bitstream, "0"); }
		if(source[i] & 0x10) { concat(precrc_bitstream, "1"); } else { concat(precrc_bitstream, "0"); }
		if(source[i] & 0x08) { concat(precrc_bitstream, "1"); } else { concat(precrc_bitstream, "0"); }
		if(source[i] & 0x04) { concat(precrc_bitstream, "1"); } else { concat(precrc_bitstream, "0"); }
		if(source[i] & 0x02) { concat(precrc_bitstream, "1"); } else { concat(precrc_bitstream, "0"); }
		if(source[i] & 0x01) { concat(precrc_bitstream, "1"); } else { concat(precrc_bitstream, "0"); }
	}
	if(debug) { printf("CRC bitstream:\n%s\n", precrc_bitstream); }
	
	/* pre-CRC bit stream byte reversal */
	for(i = 0; i < (input_length + 2); i++) {
		precrc_bitstream_reversed[0 + (i * 8)] = precrc_bitstream[7 + (i * 8)];
		precrc_bitstream_reversed[1 + (i * 8)] = precrc_bitstream[6 + (i * 8)];
		precrc_bitstream_reversed[2 + (i * 8)] = precrc_bitstream[5 + (i * 8)];
		precrc_bitstream_reversed[3 + (i * 8)] = precrc_bitstream[4 + (i * 8)];
		precrc_bitstream_reversed[4 + (i * 8)] = precrc_bitstream[3 + (i * 8)];
		precrc_bitstream_reversed[5 + (i * 8)] = precrc_bitstream[2 + (i * 8)];
		precrc_bitstream_reversed[6 + (i * 8)] = precrc_bitstream[1 + (i * 8)];
		precrc_bitstream_reversed[7 + (i * 8)] = precrc_bitstream[0 + (i * 8)];
	}
	precrc_bitstream_reversed[strlen(precrc_bitstream)] = '\0';
	machine_cycles = strlen(precrc_bitstream_reversed);
	if(debug) { printf("Reversed CRC bitstream:\n%s\n", precrc_bitstream_reversed); }
	
	/* Start up the machine */
	for(i = 0; i < 16; i++) {
		xor_register[i] = '0';
	}
	input_bit = precrc_bitstream_reversed[0];
	if(input_bit != xor_register[15]) { out1 = '1'; } else { out1 = '0'; }
	if(input_bit != xor_register[11]) { out2 = '1'; } else { out2 = '0'; }
	if(input_bit != xor_register[4]) { out3 = '1'; } else { out3 = '0'; }
	
	for(i = 0; i < machine_cycles; i++) {
		xor_register[15] = xor_register[14];
		xor_register[14] = xor_register[13];
		xor_register[13] = xor_register[12];
		xor_register[12] = out2;
		xor_register[11] = xor_register[10];
		xor_register[10] = xor_register[9];
		xor_register[9] = xor_register[8];
		xor_register[8] = xor_register[7];
		xor_register[7] = xor_register[6];
		xor_register[6] = xor_register[5];
		xor_register[5] = out3;
		xor_register[4] = xor_register[3];
		xor_register[3] = xor_register[2];
		xor_register[2] = xor_register[1];
		xor_register[1] = xor_register[0];
		xor_register[0] = out1;
		input_bit = precrc_bitstream_reversed[(i + 1)];
		if(input_bit != xor_register[15]) { out1 = '1'; } else { out1 = '0'; }
		if(out1 != xor_register[11]) { out2 = '1'; } else { out2 = '0'; }
		if(out1 != xor_register[4]) { out3 = '1'; } else { out3 = '0'; }
	}
	
	for(i = 0; i < 16; i++) {
		data_prefix_bitstream[i + 5] = xor_register[15 - i];
	}
	data_prefix_bitstream[16 + 5] = '\0';
	if(debug) { printf("Data Prefix:\n%s\n", data_prefix_bitstream); }
	
	return;
}

void i1_base11(char binary_string[], unsigned char source[], int length)
{
	int input_length, blocks, remainder, i, j;
	char block_binary[22];
	int block_value, c[6], weight[6];
	int binary_posn;
	
	input_length = length;
	binary_posn = strlen(binary_string);
	blocks = input_length / 6;
	remainder = input_length % 6;
	
	weight[0] = 1;
	weight[1] = 11;
	weight[2] = 121;
	weight[3] = 1331;
	weight[4] = 14641;
	weight[5] = 161051;
	
	for(i = 0; i < blocks; i++) {
		strcpy(block_binary, "");
		block_value = 0;
		binary_posn = strlen(binary_string);
		for(j = 0; j < 6; j++) {
			c[j] = posn(SODIUM, source[(i * 6) + j]);
			c[j] *= weight[j];
			block_value += c[j];
		}
		
		if(block_value & 0x100000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x80000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x40000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x20000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x10000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x8000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x4000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x2000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x1000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x800) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x400) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x200) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x100) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x80) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		
		for(j = 0; j < strlen(block_binary); j++) {
			binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
		}
		binary_string[strlen(block_binary) + binary_posn] = '\0';
		binary_posn = strlen(binary_string);
	}
	
	strcpy(block_binary, "");
	block_value = 0;
	binary_posn = strlen(binary_string);
	for(j = 0; j < remainder; j++) {
		c[j] = posn(SODIUM, source[(i * 6) + j]);
		c[j] *= weight[j];
		block_value += c[j];
	}
	
	switch(remainder) {
		case 5:
			if(block_value & 0x20000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x10000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x8000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x4000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 4:
			if(block_value & 0x2000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x1000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x800) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 3:
			if(block_value & 0x400) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x200) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x100) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x80) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 2:
			if(block_value & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 1:
			if(block_value & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		default:
			break;
	}
	
	for(j = 0; j < strlen(block_binary); j++) {
		binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
	}
	binary_string[strlen(block_binary) + binary_posn] = '\0';
	binary_posn = strlen(binary_string);
	
	return;
}

void i2_base27(char binary_string[], unsigned char source[], int length)
{
	int input_length, blocks, remainder, i, j;
	char block_binary[25];
	int block_value, c[5], weight[5];
	int binary_posn;
	
	input_length = length;
	blocks = input_length / 5;
	remainder = input_length % 5;
	binary_posn = strlen(binary_string);
	
	weight[0] = 1;
	weight[1] = 27;
	weight[2] = 729;
	weight[3] = 19683;
	weight[4] = 531441;
	
	for(i = 0; i < blocks; i++) {
		strcpy(block_binary, "");
		block_value = 0;
		for(j = 0; j < 5; j++) {
			c[j] = posn(COBALT, source[(i * 5) + j]);
			c[j] *= weight[j];
			block_value += c[j];
		}
		
		if(block_value & 0x800000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x400000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x200000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x100000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x80000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x40000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x20000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x10000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x8000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x4000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x2000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x1000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x800) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x400) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x200) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x100) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x80) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		
		for(j = 0; j < strlen(block_binary); j++) {
			binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
		}
		binary_string[strlen(block_binary) + binary_posn] = '\0';
		binary_posn = strlen(binary_string);
	}
	
	strcpy(block_binary, "");
	block_value = 0;
	for(j = 0; j < remainder; j++) {
		c[j] = posn(COBALT, source[(i * 5) + j]);
		c[j] *= weight[j];
		block_value += c[j];
	}
	
	switch(remainder) {
		case 4:
			if(block_value & 0x80000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x40000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x20000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x10000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x8000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 3:
			if(block_value & 0x4000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x2000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x1000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x800) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x400) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 2:
			if(block_value & 0x200) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x100) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x80) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 1:
			if(block_value & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		default:
			break;
	}
	
	for(j = 0; j < strlen(block_binary); j++) {
		binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
	}
	binary_string[strlen(block_binary) + binary_posn] = '\0';
	binary_posn = strlen(binary_string);
	
	return;
}

void i3_base37(char binary_string[], unsigned char source[], int length)
{
	int input_length, blocks, remainder, i, j;
	char block_binary[22];
	int block_value, c[6], weight[6];
	int binary_posn;
	
	input_length = length;
	blocks = input_length / 4;
	remainder = input_length % 4;
	binary_posn = strlen(binary_string);
	
	weight[0] = 1;
	weight[1] = 37;
	weight[2] = 1369;
	weight[3] = 50653;
	
	for(i = 0; i < blocks; i++) {
		strcpy(block_binary, "");
		block_value = 0;
		for(j = 0; j < 4; j++) {
			c[j] = posn(RUBIDIUM, source[(i * 4) + j]);
			c[j] *= weight[j];
			block_value += c[j];
		}
		
		if(block_value & 0x100000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x80000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x40000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x20000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x10000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x8000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x4000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x2000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x1000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x800) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x400) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x200) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x100) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x80) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		
		for(j = 0; j < strlen(block_binary); j++) {
			binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
		}
		binary_string[strlen(block_binary) + binary_posn] = '\0';
		binary_posn = strlen(binary_string);
	}
	
	strcpy(block_binary, "");
	block_value = 0;
	for(j = 0; j < remainder; j++) {
		c[j] = posn(RUBIDIUM, source[(i * 4) + j]);
		c[j] *= weight[j];
		block_value += c[j];
	}
	
	switch(remainder) {
		case 3:
			if(block_value & 0x8000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x4000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x2000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x1000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x800) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 2:
			if(block_value & 0x400) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x200) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x100) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x80) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 1:
			if(block_value & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		default:
			break;
	}
	
	for(j = 0; j < strlen(block_binary); j++) {
		binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
	}
	binary_string[strlen(block_binary) + binary_posn] = '\0';
	binary_posn = strlen(binary_string);
	
	return;
}

void i4_base41(char binary_string[], unsigned char source[], int length)
{
	int input_length, blocks, remainder, i, j;
	char block_binary[23];
	int block_value, c[6], weight[6];
	int binary_posn;
	
	input_length = length;
	blocks = input_length / 4;
	remainder = input_length % 4;
	binary_posn = strlen(binary_string);
	
	weight[0] = 1;
	weight[1] = 41;
	weight[2] = 1681;
	weight[3] = 68921;
	
	for(i = 0; i < blocks; i++) {
		strcpy(block_binary, "");
		block_value = 0;
		for(j = 0; j < 4; j++) {
			c[j] = posn(NIOBIUM, source[(i * 4) + j]);
			c[j] *= weight[j];
			block_value += c[j];
		}
		
		if(block_value & 0x200000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x100000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x80000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x40000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x20000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x10000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x8000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x4000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x2000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x1000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x800) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x400) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x200) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x100) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x80) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(block_value & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		
		for(j = 0; j < strlen(block_binary); j++) {
			binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
		}
		binary_string[strlen(block_binary) + binary_posn] = '\0';
		binary_posn = strlen(binary_string);
	}
	
	strcpy(block_binary, "");
	block_value = 0;
	for(j = 0; j < remainder; j++) {
		c[j] = posn(NIOBIUM, source[(i * 4) + j]);
		c[j] *= weight[j];
		block_value += c[j];
	}
	
	switch(remainder) {
		case 3:
			if(block_value & 0x10000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x8000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x4000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x2000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x1000) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x800) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 2:
			if(block_value & 0x400) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x200) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x100) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x80) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		case 1:
			if(block_value & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
			if(block_value & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		default:
			break;
	}

	for(j = 0; j < strlen(block_binary); j++) {
		binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
	}
	binary_string[strlen(block_binary) + binary_posn] = '\0';
	binary_posn = strlen(binary_string);
	
	return;
}

void base128(char binary_string[], unsigned char source[], int length)
{
	int i, j, input_length;
	char block_binary[9];
	int binary_posn;
	
	input_length = length;
	binary_posn = strlen(binary_string);
	
	for(i = 0; i < input_length; i++) {
		strcpy(block_binary, "");
		
		if(source[i] & 0x40) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(source[i] & 0x20) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(source[i] & 0x10) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(source[i] & 0x08) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(source[i] & 0x04) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(source[i] & 0x02) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		if(source[i] & 0x01) { concat(block_binary, "1"); } else { concat(block_binary, "0"); }
		
		for(j = 0; j < strlen(block_binary); j++) {
			binary_string[strlen(block_binary) + binary_posn - j - 1] = block_binary[j];
		}
		binary_string[strlen(block_binary) + binary_posn] = '\0';
		binary_posn = strlen(binary_string);
	}
	
	return;
}

void protect_ecc000(char protected_stream[], char unprotected_stream[])
{
	/* ECC 000 - No processing needed */
	
	strcpy(protected_stream, unprotected_stream);
}

void protect_ecc050(char protected_stream[], char unprotected_stream[])
{
	/* ECC 050 - 4-3-3 convolutional code */
	/* State machine illustrated in figure K1 */
	char top_reg[4];
	char mid_reg[4];
	char low_reg[4];
	char u1, u2, u3;
	char output[6];
	char gate_input[8];
	int i, blocks, j, count;
	
	strcpy(protected_stream, "");
	
	for(i = 0; i < 3; i++) {
		top_reg[i] = '0';
		mid_reg[i] = '0';
		low_reg[i] = '0';
	}
	
	for(i = 0; i < (strlen(unprotected_stream) % 3); i++){
		concat(unprotected_stream, "0");
	}
	blocks = strlen(unprotected_stream) / 3;
	blocks += 3;
	for(i = 0; i < blocks; i++) {
		if(i < (blocks - 3)) {
			u1 = unprotected_stream[3 * i];
			u2 = unprotected_stream[(3 * i) + 1];
			u3 = unprotected_stream[(3 * i) + 2];
		} else {
			u1 = '0';
			u2 = '0';
			u3 = '0';
		}
		
		/* Gate 1 */
		for(j = 0; j < 8; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u1;
		gate_input[1] = mid_reg[2];
		gate_input[2] = low_reg[0];
		gate_input[3] = low_reg[1];
		gate_input[4] = low_reg[2];
		
		count = 0;
		for(j = 0; j < 5; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[0] = '1'; } else { output[0] = '0'; }
		
		/* Gate 2 */
		for(j = 0; j < 8; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = top_reg[1];
		gate_input[1] = top_reg[2];
		gate_input[2] = u2;
		gate_input[3] = mid_reg[0];
		gate_input[4] = mid_reg[2];
		
		count = 0;
		for(j = 0; j < 5; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[1] = '1'; } else { output[1] = '0'; }
		
		/* Gate 3 */
		for(j = 0; j < 8; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = top_reg[0];
		gate_input[1] = top_reg[1];
		gate_input[2] = top_reg[2];
		gate_input[3] = mid_reg[0];
		gate_input[4] = u3;
		gate_input[5] = low_reg[0];
		
		count = 0;
		for(j = 0; j < 6; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[2] = '1'; } else { output[2] = '0'; }
		
		/* Gate 4 */
		for(j = 0; j < 8; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u1;
		gate_input[1] = top_reg[0];
		gate_input[2] = u2;
		gate_input[3] = mid_reg[0];
		gate_input[4] = mid_reg[1];
		gate_input[5] = u3;
		gate_input[6] = low_reg[0];
		gate_input[7] = low_reg[2];
		
		count = 0;
		for(j = 0; j < 8; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[3] = '1'; } else { output[3] = '0'; }
		
		output[4] = '\0';

		concat(protected_stream, output);
		
		/* Shift registers right */
		top_reg[2] = top_reg[1];
		top_reg[1] = top_reg[0];
		top_reg[0] = u1;
		mid_reg[2] = mid_reg[1];
		mid_reg[1] = mid_reg[0];
		mid_reg[0] = u2;
		low_reg[2] = low_reg[1];
		low_reg[1] = low_reg[0];
		low_reg[0] = u3;
	}
}

void protect_ecc080(char protected_stream[], char unprotected_stream[])
{
	/* ECC 080 - 3-2-11 convolutional code */
	/* State machine illustrated in figure K2 */
	char top_reg[12];
	char low_reg[12];
	char u1, u2;
	char output[4];
	char gate_input[12];
	int i, j, count, blocks;
	
	strcpy(protected_stream, "");
	
	for(i = 0; i < 12; i++) {
		top_reg[i] = '0';
		low_reg[i] = '0';
	}
	
	for(i = 0; i < (strlen(unprotected_stream) % 2); i++){
		concat(unprotected_stream, "0");
	}
	blocks = strlen(unprotected_stream) / 2;
	blocks += 11;
	for(i = 0; i < blocks; i++) {
		if(i < (blocks - 11)) {
			u1 = unprotected_stream[2 * i];
			u2 = unprotected_stream[(2 * i) + 1];
		} else {
			u1 = '0';
			u2 = '0';
		}
		
		/* Gate 1 */
		for(j = 0; j < 12; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u1;
		gate_input[1] = top_reg[0];
		gate_input[2] = top_reg[2];
		gate_input[3] = top_reg[4];
		gate_input[4] = top_reg[5];
		gate_input[5] = top_reg[6];
		gate_input[6] = top_reg[9];
		gate_input[7] = low_reg[2];
		gate_input[8] = low_reg[6];
		gate_input[9] = low_reg[7];
		gate_input[10] = low_reg[10];
		
		count = 0;
		for(j = 0; j < 11; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[0] = '1'; } else { output[0] = '0'; }
		
		/* Gate 2 */
		for(j = 0; j < 12; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = top_reg[0];
		gate_input[1] = top_reg[3];
		gate_input[2] = top_reg[4];
		gate_input[3] = top_reg[7];
		gate_input[4] = top_reg[8];
		gate_input[5] = top_reg[9];
		gate_input[6] = u2;
		gate_input[7] = low_reg[2];
		gate_input[8] = low_reg[5];
		gate_input[9] = low_reg[7];
		gate_input[10] = low_reg[8];
		
		count = 0;
		for(j = 0; j < 11; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[1] = '1'; } else { output[1] = '0'; }
		
		/* Gate 3 */
		for(j = 0; j < 12; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u1;
		gate_input[1] = top_reg[4];
		gate_input[2] = top_reg[5];
		gate_input[3] = top_reg[6];
		gate_input[4] = u2;
		gate_input[5] = low_reg[0];
		gate_input[6] = low_reg[1];
		gate_input[7] = low_reg[3];
		gate_input[8] = low_reg[6];
		gate_input[9] = low_reg[8];
		gate_input[10] = low_reg[10];
		
		count = 0;
		for(j = 0; j < 11; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[2] = '1'; } else { output[2] = '0'; }
		
		output[3] = '\0';
		
		concat(protected_stream, output);
		
		/* Shift registers right */
		top_reg[9] = top_reg[8];
		top_reg[8] = top_reg[7];
		top_reg[7] = top_reg[6];
		top_reg[6] = top_reg[5];
		top_reg[5] = top_reg[4];
		top_reg[4] = top_reg[3];
		top_reg[3] = top_reg[2];
		top_reg[2] = top_reg[1];
		top_reg[1] = top_reg[0];
		top_reg[0] = u1;
		low_reg[10] = low_reg[9];
		low_reg[9] = low_reg[8];
		low_reg[8] = low_reg[7];
		low_reg[7] = low_reg[6];
		low_reg[6] = low_reg[5];
		low_reg[5] = low_reg[4];
		low_reg[4] = low_reg[3];
		low_reg[3] = low_reg[2];
		low_reg[2] = low_reg[1];
		low_reg[1] = low_reg[0];
		low_reg[0] = u2;
		
	}
}

void protect_ecc100(char protected_stream[], char unprotected_stream[])
{
	/* ECC 100 - 2-1-15 convolutional code */
	/* State machine illustrated in figure k3 */
	char reg[16];
	char u;
	char output[3];
	char gate_input[10];
	int i, j, count, blocks;
	
	strcpy(protected_stream, "");
	
	for(i = 0; i < 16; i++) {
		reg[i] = '0';
	}
	
	blocks = strlen(unprotected_stream);
	blocks += 15;
	for(i = 0; i < blocks; i++) {
		if(i < (blocks - 15)) {
			u = unprotected_stream[i];
		} else {
			u = '0';
		}
		
		/* Gate 1 */
		for(j = 0; j < 10; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u;
		gate_input[1] = reg[1];
		gate_input[2] = reg[4];
		gate_input[3] = reg[5];
		gate_input[4] = reg[6];
		gate_input[5] = reg[7];
		gate_input[6] = reg[8];
		gate_input[7] = reg[9];
		gate_input[8] = reg[14];
		
		count = 0;
		for(j = 0; j < 9; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[0] = '1'; } else { output[0] = '0'; }
		
		/* Gate 2 */
		for(j = 0; j < 10; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u;
		gate_input[1] = reg[0];
		gate_input[2] = reg[2];
		gate_input[3] = reg[3];
		gate_input[4] = reg[5];
		gate_input[5] = reg[10];
		gate_input[6] = reg[12];
		gate_input[7] = reg[13];
		gate_input[8] = reg[14];
		
		count = 0;
		for(j = 0; j < 9; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[1] = '1'; } else { output[1] = '0'; }
		
		output[2] = '\0';
		
		concat(protected_stream, output);
		
		/* Shift register right */
		reg[14] = reg[13];
		reg[13] = reg[12];
		reg[12] = reg[11];
		reg[11] = reg[10];
		reg[10] = reg[9];
		reg[9] = reg[8];
		reg[8] = reg[7];
		reg[7] = reg[6];
		reg[6] = reg[5];
		reg[5] = reg[4];
		reg[4] = reg[3];
		reg[3] = reg[2];
		reg[2] = reg[1];
		reg[1] = reg[0];
		reg[0] = u;
	}
}

void protect_ecc140(char protected_stream[], char unprotected_stream[])
{
	/* ECC 140 - 4-1-13 convolutional coding */
	/* State machine illustrated in figure k3 */
	char reg[13];
	char u;
	char output[5];
	char gate_input[12];
	int i, j, count, blocks;
	
	strcpy(protected_stream, "");
	
	for(i = 0; i < 13; i++) {
		reg[i] = '0';
	}
	
	blocks = strlen(unprotected_stream);
	blocks += 13;
	for(i = 0; i < blocks; i++) {
		if(i < (blocks - 13)) {
			u = unprotected_stream[i];
		} else {
			u = '0';
		}
		
		/* Gate 1 */
		for(j = 0; j < 12; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u;
		gate_input[1] = reg[3];
		gate_input[2] = reg[6];
		gate_input[3] = reg[9];
		gate_input[4] = reg[11];
		gate_input[5] = reg[12];
		
		count = 0;
		for(j = 0; j < 6; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[0] = '1'; } else { output[0] = '0'; }
		
		/* Gate 2 */
		for(j = 0; j < 12; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u;
		gate_input[1] = reg[2];
		gate_input[2] = reg[3];
		gate_input[3] = reg[6];
		gate_input[4] = reg[7];
		gate_input[5] = reg[8];
		gate_input[6] = reg[9];
		gate_input[7] = reg[10];
		gate_input[8] = reg[12];
		
		count = 0;
		for(j = 0; j < 9; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[1] = '1'; } else { output[1] = '0'; }
		
		/* Gate 3 */
		for(j = 0; j < 12; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u;
		gate_input[1] = reg[0];
		gate_input[2] = reg[1];
		gate_input[3] = reg[3];
		gate_input[4] = reg[4];
		gate_input[5] = reg[6];
		gate_input[6] = reg[8];
		gate_input[7] = reg[10];
		gate_input[8] = reg[11];
		gate_input[9] = reg[12];
		
		count = 0;
		for(j = 0; j < 10; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[2] = '1'; } else { output[2] = '0'; }
		
		/* Gate 4 */
		for(j = 0; j < 12; j++) {
			gate_input[j] = '0';
		}
		
		gate_input[0] = u;
		gate_input[1] = reg[0];
		gate_input[2] = reg[1];
		gate_input[3] = reg[3];
		gate_input[4] = reg[4];
		gate_input[5] = reg[6];
		gate_input[6] = reg[8];
		gate_input[7] = reg[9];
		gate_input[8] = reg[10];
		gate_input[9] = reg[11];
		gate_input[10] = reg[12];
		
		count = 0;
		for(j = 0; j < 11; j++) {
			if(gate_input[j] == '1') {
				count++;
			}
		}
		if((count & 0x01) == 0x01) { output[3] = '1'; } else { output[3] = '0'; }
		
		output[4] = '\0';
		
		concat(protected_stream, output);
		
		/* Shift register right */
		reg[12] = reg[11];
		reg[11] = reg[10];
		reg[10] = reg[9];
		reg[9] = reg[8];
		reg[8] = reg[7];
		reg[7] = reg[6];
		reg[6] = reg[5];
		reg[5] = reg[4];
		reg[4] = reg[3];
		reg[3] = reg[2];
		reg[2] = reg[1];
		reg[1] = reg[0];
		reg[0] = u;
	}

}

int matrix89(struct zint_symbol *symbol, unsigned char source[], int length)
{
	int i, j, input_length, scheme;
	char unprotected_stream[2210];
	char data_prefix_bitstream[31];
	char protected_stream[6630];
	char unrandomized_stream[2210];
	char master_random_stream[2214];
	char randomized_stream[2210];
	char header[20];
	int symbol_size, hex_segment, width;
	int error_number;
	
        input_length = length;
        error_number = 0;
	
	symbol_size = 0;
	for(i = 0; i < input_length; i++) {
		if(source[i] > 127) {
			strcpy(symbol->errtxt, "Data Matrix ECC 000 - 140 doesn't support extended ASCII");
			return ERROR_INVALID_DATA;
		}
	}
	
	/* Decide which encoding scheme to use */
	scheme = 128;
	if(!(is_sane(NIOBIUM, source, length))) { scheme = 41; }
	if(!(is_sane(RUBIDIUM, source, length))) { scheme = 37; }
	if(!(is_sane(COBALT, source, length))) { scheme = 27; }
	if(!(is_sane(SODIUM, source, length))) { scheme = 11; }
	
	/* Data Prefix Bit Stream = Format ID + CRC + Data Length */
	
	/* Format ID (5 bits) */
	switch(scheme) {
		case 11: strcpy(data_prefix_bitstream, "00000"); break;
		case 27: strcpy(data_prefix_bitstream, "00001"); break;
		case 37: strcpy(data_prefix_bitstream, "00011"); break;
		case 41: strcpy(data_prefix_bitstream, "00010"); break;
		default: strcpy(data_prefix_bitstream, "00100"); break;
	}
	
	/* CRC Value (16 bit) */
	crc_machine(data_prefix_bitstream, scheme, source, length);
	
	/* Data length (9 bit) */
	if(input_length & 0x01) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	if(input_length & 0x02) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	if(input_length & 0x04) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	if(input_length & 0x08) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	if(input_length & 0x10) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	if(input_length & 0x20) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	if(input_length & 0x40) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	if(input_length & 0x80) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	if(input_length & 0x100) { concat(data_prefix_bitstream, "1"); } else { concat(data_prefix_bitstream, "0"); }
	
	/* Unprotected Bit Stream = Data Prefix Bitstream + Encoded Data */
	
	strcpy(unprotected_stream, data_prefix_bitstream);
	
	switch(scheme) {
		case 11:
			if(input_length >= 618) {
				strcpy(symbol->errtxt, "Input data too long"); return ERROR_TOO_LONG;
			}
			break;
		case 27:
			if(input_length >= 450) {
				strcpy(symbol->errtxt, "Input data too long"); return ERROR_TOO_LONG;
			}
			break;
		case 37:
			if(input_length >= 412) {
				strcpy(symbol->errtxt, "Input data too long"); return ERROR_TOO_LONG;
			}
			break;
		case 41:
			if(input_length >= 396) {
				strcpy(symbol->errtxt, "Input data too long"); return ERROR_TOO_LONG;
			}
			break;
		case 128:
			if(input_length >= 311) {
				strcpy(symbol->errtxt, "Input data too long"); return ERROR_TOO_LONG;
			}
			break;
	}
	
	switch(scheme) {
		case 11: i1_base11(unprotected_stream, source, length); break;
		case 27: i2_base27(unprotected_stream, source, length); break;
		case 37: i3_base37(unprotected_stream, source, length); break;
		case 41: i4_base41(unprotected_stream, source, length); break;
		default: base128(unprotected_stream, source, length); break;
	}
	
	/* Header (ECC Bit field) LSB first */
	switch(symbol->option_1) {
		case 2: strcpy(header, "0111111"); break; /* ECC 000 */
		case 3: strcpy(header, "0111000000000111000"); break; /* ECC 050 */
		case 4: strcpy(header, "0111000000111000111"); break; /* ECC 080 */
		case 5: strcpy(header, "0111000000111111111"); break; /* ECC 100 */
		case 6: strcpy(header, "0111000111000111111"); break; /* ECC 140 */
	}
	
	/* Generate Protected Bit Stream */
	switch(symbol->option_1) {
		case 2: protect_ecc000(protected_stream, unprotected_stream); break;
		case 3: protect_ecc050(protected_stream, unprotected_stream); break;
		case 4: protect_ecc080(protected_stream, unprotected_stream); break;
		case 5: protect_ecc100(protected_stream, unprotected_stream); break;
		case 6: protect_ecc140(protected_stream, unprotected_stream); break;
	}
	
	if((strlen(protected_stream) + strlen(header)) > 2209) {
		strcpy(symbol->errtxt, "Input data too long");
		return ERROR_TOO_LONG;
	}
	
	/* Construct Unrandomized Bit Stream */
	strcpy(unrandomized_stream, header);
	concat(unrandomized_stream, protected_stream);
	
	/* Determine Symbol Size */
	for(i = 20; i >= 0; i--) {
		if(MatrixMaxCapacities[i] > strlen(unrandomized_stream)) {
			symbol_size = i;
		}
	}
	
	if((symbol->option_2 < 0) || (symbol->option_2 > 21)) {
		strcpy(symbol->errtxt, "Invalid symbol size");
		error_number = WARN_INVALID_OPTION;
		symbol->option_2 = 0;
	}
	
	if((symbol->option_2 - 1) > symbol_size) {
		symbol_size = (symbol->option_2 - 1);
	}

	if(((symbol->option_2 - 1) < symbol_size) && (symbol->option_2 != 0)) {
		strcpy(symbol->errtxt, "Unable to fit data in specified symbol size");
		error_number = WARN_INVALID_OPTION;
	}
	
	/* Add trailer (pad bits) */
	input_length = strlen(unrandomized_stream);
	for(i = input_length; i < MatrixMaxCapacities[symbol_size]; i++) {
		concat(unrandomized_stream, "0");
	}
	
	/* Load master random stream */
	strcpy(master_random_stream, "");
	for(i = 0; i < 276; i++) {
		hex_segment = MasterRandomStream[i];
		if(hex_segment & 0x80) { concat(master_random_stream, "1"); } else { concat(master_random_stream, "0"); }
		if(hex_segment & 0x40) { concat(master_random_stream, "1"); } else { concat(master_random_stream, "0"); }
		if(hex_segment & 0x20) { concat(master_random_stream, "1"); } else { concat(master_random_stream, "0"); }
		if(hex_segment & 0x10) { concat(master_random_stream, "1"); } else { concat(master_random_stream, "0"); }
		if(hex_segment & 0x08) { concat(master_random_stream, "1"); } else { concat(master_random_stream, "0"); }
		if(hex_segment & 0x04) { concat(master_random_stream, "1"); } else { concat(master_random_stream, "0"); }
		if(hex_segment & 0x02) { concat(master_random_stream, "1"); } else { concat(master_random_stream, "0"); }
		if(hex_segment & 0x01) { concat(master_random_stream, "1"); } else { concat(master_random_stream, "0"); }
	}
	
	/* Randomizing Algorithm */
	
	strcpy(randomized_stream, "");
	for(i = 0; i < strlen(unrandomized_stream); i++) {
		if(unrandomized_stream[i] != master_random_stream[i]) {
			concat(randomized_stream, "1");
		} else {
			concat(randomized_stream, "0");
		}
	}
	
	/* Placement Algorithm */
	width = (symbol_size * 2) + 7;
	
	symbol->row_height[0] = 1;
	/* Fill corners */
	set_module(symbol, 0, 0);
	set_module(symbol, 0, width + 1);
	set_module(symbol, width + 1, 0);
	set_module(symbol, width + 1, width + 1);
	for(i = 0; i < width; i++) {
		/* Fill sides */
		set_module(symbol, i + 1, 0);
		set_module(symbol, width + 1, i + 1);
		if((i % 2) == 0) {
			set_module(symbol, i, width + 1);
			set_module(symbol, 0, i);
		}
		for(j = 0; j < width; j++) {
			
			switch(symbol_size) {
				case 0: if(randomized_stream[tableh1[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 1: if(randomized_stream[tableh2[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 2: if(randomized_stream[tableh3[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 3: if(randomized_stream[tableh4[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 4: if(randomized_stream[tableh5[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 5: if(randomized_stream[tableh6[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 6: if(randomized_stream[tableh7[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 7: if(randomized_stream[tableh8[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 8: if(randomized_stream[tableh9[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 9: if(randomized_stream[tableh10[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 10: if(randomized_stream[tableh11[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 11: if(randomized_stream[tableh12[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 12: if(randomized_stream[tableh13[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 13: if(randomized_stream[tableh14[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 14: if(randomized_stream[tableh15[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 15: if(randomized_stream[tableh16[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 16: if(randomized_stream[tableh17[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 17: if(randomized_stream[tableh18[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 18: if(randomized_stream[tableh19[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 19: if(randomized_stream[tableh20[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
				case 20: if(randomized_stream[tableh21[(i * width) + j]] == '1') { set_module(symbol, i + 1, j + 1); } break;
			}
		}
		symbol->row_height[i + 1] = 1;
	}
	
	symbol->row_height[width + 1] = 1;
	symbol->rows = width + 2;
	symbol->width = width + 2;
	
	return error_number;
}

int dmatrix(struct zint_symbol *symbol, unsigned char source[], int length)
{
	int error_number;
	
	if(symbol->option_1 <= 1) {
		/* ECC 200 */
		error_number = data_matrix_200(symbol, source, length);
	} else {
		/* ECC 000 - 140 */
		error_number = matrix89(symbol, source, length);
	}

	return error_number;
}
