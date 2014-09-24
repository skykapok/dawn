#include "label.h"

#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"

#include <android/log.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define LOG_TAG "EJOY2D"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#define FONT_DEF "/system/fonts/DroidSans.ttf"

struct font {
	int ascent;
	int descent;
	float scale;
};

static stbtt_fontinfo info;
static uint8_t *buffer;

int
font_module_init() {
	long size;
	FILE* f = fopen(FONT_DEF, "rb");
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	fseek(f, 0, SEEK_SET);

	buffer = malloc(size);
	fread(buffer, size, 1, f);
	fclose(f);

	if (!stbtt_InitFont(&info, buffer, 0)) {
		LOGE("create font failed");
		return 0;
	}

	return 1;
}

void
font_module_destroy() {
	free(buffer);
	buffer = NULL;
}

void
font_size(const char *str, int unicode, struct font_context *ctx) {
	struct font *font = (struct font*)(ctx->font);
	float s = font->scale;

	int x0, y0, x1, y1;
	stbtt_GetCodepointBitmapBox(&info, unicode, s, s, &x0, &y0, &x1, &y1);

	int adv;
	stbtt_GetCodepointHMetrics(&info, unicode, &adv, NULL);
	adv *= font->scale;

	ctx->w = adv;
	ctx->h = font->ascent + y1;
}

void
font_glyph(const char *str, int unicode, void *buffer, struct font_context *ctx) {
	struct font *font = (struct font*)(ctx->font);
	float s = font->scale;

	int x0, y0, x1, y1;
	stbtt_GetCodepointBitmapBox(&info, unicode, s, s, &x0, &y0, &x1, &y1);

	uint8_t *p = buffer + (font->ascent + y0) * ctx->w + x0;
	stbtt_MakeCodepointBitmap(&info, p, x1 - x0, y1 - y0, ctx->w, s, s, unicode);
}

void
font_create(int font_size, struct font_context *ctx) {
	struct font *font = malloc(sizeof(struct font));
	font->scale = stbtt_ScaleForPixelHeight(&info, font_size * 2);
	stbtt_GetFontVMetrics(&info, &(font->ascent), &(font->descent), NULL);
	font->ascent *= font->scale;
	font->descent *= font->scale;
	ctx->font = font;
}

void
font_release(struct font_context *ctx) {
	free(ctx->font);
	ctx->font = NULL;
}
