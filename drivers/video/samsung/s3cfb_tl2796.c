/*
 * s6e63m0 AMOLED Panel Driver for the Samsung Universal board
 *
 * Derived from drivers/video/omap/lcd-apollon.c
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#include <linux/wait.h>
#include <linux/fb.h>
#include <linux/debugfs.h>
#include <linux/delay.h>
#include <linux/gpio.h>
#include <linux/seq_file.h>
#include <linux/spi/spi.h>
#include <linux/lcd.h>
#include <linux/backlight.h>
#include <linux/tl2796.h>
#include <plat/gpio-cfg.h>
#include <plat/regs-fb.h>
#include <linux/earlysuspend.h>
#include <linux/miscdevice.h>

#define SLEEPMSEC		0x1000
#define ENDDEF			0x2000
#define DEFMASK		0xFF00

#define NUM_GAMMA_REGS	21

//int hacky_v1_offset[3] = {-52, -55, -46};
int hacky_v1_offset[3] = {-15, -15, -17};
static unsigned int min_brightness = 1;
static unsigned int gamma = 15;

// MIDNIGHT lower-brightness adjustments 
// 0 = driver default, 3 = Midnight default, 4 = lowest
unsigned int bmult = 3; 

static const struct tl2796_gamma_adj_points default_gamma_adj_points = {
	.v0 = BV_0,
	.v1 = BV_1,
	.v19 = BV_19,
	.v43 = BV_43,
	.v87 = BV_87,
	.v171 = BV_171,
	.v255 = BV_255,
};

struct tl2796_gamma_reg_offsets {
	s16 v[3][6];
};

struct s5p_lcd{
	int ldi_enable;
	int bl;
	const struct tl2796_gamma_adj_points *gamma_adj_points;
	struct tl2796_gamma_reg_offsets gamma_reg_offsets;
	u32 color_mult[3];
	struct mutex	lock;
	struct device *dev;
	struct spi_device *g_spi;
	struct s5p_panel_data	*data;
	struct backlight_device *bl_dev;
	struct early_suspend    early_suspend;
	struct dentry *debug_dir;
};

struct s5p_lcd *lcd_;

u32 original_color_adj_mults[3];
unsigned int panel_config_sequence = 0;

static const u16 s6e63m0_SEQ_ETC_SETTING_SAMSUNG[] = {
	/* ETC Condition Set Command  */
	0x0F6,
	0x100,	0x18E,
	0x107,
	0x0B3,
	0x16C,
	0x0B5,
	0x12C,	0x112,
	0x10C,	0x10A,
	0x110,	0x10E,
	0x117,	0x113,
	0x11F,	0x11A,
	0x12A,	0x124,
	0x11F,	0x11B,
	0x11A,	0x117,
	0x12B,	0x126,
	0x122,	0x120,
	0x13A,	0x134,
	0x130,	0x12C,
	0x129,	0x126,
	0x125,	0x123,
	0x121,	0x120,
	0x11E,	0x11E,
	0x0B6,
	0x100,	0x100,
	0x111,	0x122,
	0x133,	0x144,
	0x144,	0x144,
	0x155,	0x155,
	0x166,	0x166,
	0x166,	0x166,
	0x166,	0x166,
	0x0B7,
	0x12C,	0x112,
	0x10C,	0x10A,
	0x110,	0x10E,
	0x117,	0x113,
	0x11F,	0x11A,
	0x12A,	0x124,
	0x11F,	0x11B,
	0x11A,	0x117,
	0x12B,	0x126,
	0x122,	0x120,
	0x13A,	0x134,
	0x130,	0x12C,
	0x129,	0x126,
	0x125,	0x123,
	0x121,	0x120,
	0x11E,	0x11E,
	0x0B8,
	0x100,	0x100,
	0x111,	0x122,
	0x133,	0x144,
	0x144,	0x144,
	0x155,	0x155,
	0x166,	0x166,
	0x166,	0x166,
	0x166,	0x166,
	0x0B9,
	0x12C,	0x112,
	0x10C,	0x10A,
	0x110,	0x10E,
	0x117,	0x113,
	0x11F,	0x11A,
	0x12A,	0x124,
	0x11F,	0x11B,
	0x11A,	0x117,
	0x12B,	0x126,
	0x122,	0x120,
	0x13A,	0x134,
	0x130,	0x12C,
	0x129,	0x126,
	0x125,	0x123,
	0x121,	0x120,
	0x11E,	0x11E,
	0x0BA,
	0x100,	0x100,
	0x111,	0x122,
	0x133,	0x144,
	0x144,	0x144,
	0x155,	0x155,
	0x166,	0x166,
	0x166,	0x166,
	0x166,	0x166,
	0x011,
	SLEEPMSEC, 120,
	0x029,
	ENDDEF, 0x0000
};

static u32 gamma_lookup(struct s5p_lcd *lcd, u8 brightness, u32 val, int c)
{
	// c	color (red, green, blue)
	// val	brightness value (BV_0, BV_1, BV_19, BV_43, BV_87, BV_171, BV_255)
	// b	brightness value divided by brightness level

	// bl	brightness range - low
	// bh	brightness range - high

	// vl	gamma table range - low
	// vh	gamma table range - high

	// ret	return value from the gamma table

	int i;
	u32 bl = 0;
	u32 bh = 0;
	u32 vl = 0;
	u32 vh;
	u32 b;
	u32 ret;
	u64 tmp;
	struct s5p_panel_data *pdata = lcd->data;
	const struct tl2796_gamma_adj_points *bv = lcd->gamma_adj_points;

	if (!val) {
		b = 0;
	} else {
		tmp = bv->v255 - bv->v0;
		tmp *= brightness;
		do_div(tmp, 255);

		tmp *= lcd->color_mult[c];
		do_div(tmp, 0xffffffff);

		tmp *= (val - bv->v0);
		do_div(tmp, bv->v255 - bv->v0);
		b = tmp + bv->v0;
	}

	// find which entry of the gamma table fits for val
	// as a result, i becomes the index in the gamma table for val and color c
	for (i = 0; i < pdata->gamma_table_size; i++) {
		bl = bh;
		bh = pdata->gamma_table[i].brightness;
		if (bh >= b)
			break;
	}

	// save corresponding value from the gamma table as vh
	// high value of the range
	vh = pdata->gamma_table[i].v[c];

	// for special black point and gamma 0 (i==0 or i==1), return value
	// is static. vl = vh = same as the value in gamma table for i
	if (i == 0 || (b - bl) == 0) {
		ret = vl = vh;
	} else {
		// simple proportional calculation of ret
		// based on vl and vh from gamma table ranges
		vl = pdata->gamma_table[i - 1].v[c];
		tmp = (u64)vh * (b - bl) + (u64)vl * (bh - b);
		do_div(tmp, bh - bl);
		ret = tmp;
	}

	pr_debug("%s: looking for %3d %08x c %d, %08x, "
		"found %08x:%08x, v %7d:%7d, ret %7d\n",
		__func__, brightness, val, c, b, bl, bh, vl, vh, ret);

	return ret;
}

static void setup_gamma_regs(struct s5p_lcd *lcd, u16 gamma_regs[])
{
	int c, i;
	u8 brightness = lcd->bl;

    /*
     * MIDNIGHT: lower brightness, don't touch 100%, testing...
     *
     * This will reduce brightness level more at
     * low brightness than at mid/high levels. 
     * It's an ugly hack but it seems to work ok for now.
     * 
     * Tweak this with values from 1 (default driver settings) to
     * 6 (darkest adjustment) like this:
     * echo YOUR_VALUE > /sys/class/misc/rgbb_multiplier/brightness_multiplier
     */ 
    u8 brightness_orig = lcd->bl; 
    brightness = (brightness <= 0) ? 1 : brightness; // just to be sure...
    //brightness = brightness - ((255 / brightness) * bmult) + bmult;
    brightness = brightness - (255/brightness) * ( bmult*2 / (5-bmult+1) ) / bmult *2;
    brightness = (brightness > brightness_orig || brightness < min_brightness) ? min_brightness : brightness;
    
    const struct tl2796_gamma_adj_points *bv = lcd->gamma_adj_points;

	// red, green then blue
	for (c = 0; c < 3; c++) {
		// initialize v0 (black point) from the gamma table
		// vx are gamma points 1 to 4.
		// adj becomes one of the value sent to the panel
		u32 adj;
		u32 v0 = gamma_lookup(lcd, brightness, BV_0, c);
		u32 vx[6];
		u32 v1;
		u32 v255;

		// calculate gamma 0 value, based on v0 and v1
		v1 = vx[0] = gamma_lookup(lcd, brightness, bv->v1, c);
		adj = 600 - 5 - DIV_ROUND_CLOSEST(600 * v1, v0);
		adj -= lcd->gamma_reg_offsets.v[c][0];
		if (adj > 140) {
			pr_debug("%s: bad adj value %d, v0 %d, v1 %d, c %d\n",
				__func__, adj, v0, v1, c);
			if ((int)adj < 0)
				adj = 0;
			else
				adj = 140;
		}
        
        // record gamma 0
        // MIDNIGHT: take care of gamma_regs overflow resulting in completely green screen
        if((adj + hacky_v1_offset[c]) <  adj){
            gamma_regs[c] = ((adj + hacky_v1_offset[c]) > 0 && (adj <=255)) ? (adj + hacky_v1_offset[c]) | 0x100 : adj | 0x100;
        }else{
            gamma_regs[c] = 0 | 0x100;
        }
        
        // calculate brightness value for color c
		v255 = vx[5] = gamma_lookup(lcd, brightness, bv->v255, c);
		adj = 600 - 120 - DIV_ROUND_CLOSEST(600 * v255, v0);
		adj -= lcd->gamma_reg_offsets.v[c][5];
		if (adj > 380) {
			pr_debug("%s: bad adj value %d, v0 %d, v255 %d, c %d\n",
				__func__, adj, v0, v255, c);
			if ((int)adj < 0)
				adj = 0;
			else
				adj = 380;
		}
		// command to set brightness value for color c: always 0x100
		gamma_regs[3 * 5 + 2 * c] = adj >> 8 | 0x100;
		// record brightness value for color c = adj
		gamma_regs[3 * 5 + 2 * c + 1] = (adj & 0xff) | 0x100;

		vx[1] = gamma_lookup(lcd, brightness,  bv->v19, c);
		vx[2] = gamma_lookup(lcd, brightness,  bv->v43, c);
		vx[3] = gamma_lookup(lcd, brightness,  bv->v87, c);
		vx[4] = gamma_lookup(lcd, brightness, bv->v171, c);

		// calculate gamma points 4 to 1 successively
		// those are calculated from vx[4] to vx[1], based on
		// gamma table values chosen to follow current brightness
		for (i = 4; i >= 1; i--) {
			if (v1 <= vx[i + 1]) {
				adj = -1;
			} else {
				// actual calculation
				adj = DIV_ROUND_CLOSEST(320 * (v1 - vx[i]),
							v1 - vx[i + 1]) - 65;
				// new in 2.3.3: offset value based on mtp
				// offsets are calculated from screen hardware
				// readings in tl2796_read_mtp_info()
				adj -= lcd->gamma_reg_offsets.v[c][i];
			}
			if (adj > 255) {
				pr_debug("%s: bad adj value %d, "
					"vh %d, v %d, c %d\n",
					__func__, adj, vx[i + 1], vx[i], c);
				if ((int)adj < 0)
					adj = 0;
				else
					adj = 255;
			}
			gamma_regs[3 * i + c] = adj | 0x100;
		}
	}
}

static int s6e63m0_spi_write_driver(struct s5p_lcd *lcd, u16 reg)
{
	u16 buf[1];
	int ret;
	struct spi_message msg;

	struct spi_transfer xfer = {
		.len	= 2,
		.tx_buf	= buf,
	};

	buf[0] = reg;

	spi_message_init(&msg);
	spi_message_add_tail(&xfer, &msg);

	ret = spi_sync(lcd->g_spi, &msg);

	if (ret < 0)
		pr_err("%s error\n", __func__);

	return ret ;
}

static void s6e63m0_panel_send_sequence(struct s5p_lcd *lcd,
	const u16 *wbuf)
{
	int i = 0;
	while ((wbuf[i] & DEFMASK) != ENDDEF) {
		if ((wbuf[i] & DEFMASK) != SLEEPMSEC) {
			s6e63m0_spi_write_driver(lcd, wbuf[i]);
			i += 1;
		} else {
			msleep(wbuf[i+1]);
			i += 2;
		}
	}
}

static void update_brightness(struct s5p_lcd *lcd)
{
	u16 gamma_regs[27];

	gamma_regs[0] = 0x0FA;
	gamma_regs[1] = 0x102;
	gamma_regs[23] = 0x0FA;
	gamma_regs[24] = 0x103;
	gamma_regs[25] = ENDDEF;
	gamma_regs[26] = 0x0000;

	setup_gamma_regs(lcd, gamma_regs + 2);

	s6e63m0_panel_send_sequence(lcd, gamma_regs);
}

static void tl2796_ldi_enable(struct s5p_lcd *lcd)
{
	struct s5p_panel_data *pdata = lcd->data;

	mutex_lock(&lcd->lock);

	s6e63m0_panel_send_sequence(lcd, pdata->seq_display_set);
	update_brightness(lcd);
    s6e63m0_panel_send_sequence(lcd, s6e63m0_SEQ_ETC_SETTING_SAMSUNG);

	lcd->ldi_enable = 1;

	mutex_unlock(&lcd->lock);
}

static void tl2796_ldi_disable(struct s5p_lcd *lcd)
{
	struct s5p_panel_data *pdata = lcd->data;

	mutex_lock(&lcd->lock);

	lcd->ldi_enable = 0;
	s6e63m0_panel_send_sequence(lcd, pdata->standby_on);

	mutex_unlock(&lcd->lock);
}

static int s5p_bl_update_status(struct backlight_device *bd)
{
	struct s5p_lcd *lcd = bl_get_data(bd);
	int bl = bd->props.brightness;

	pr_debug("\nupdate status brightness %d\n",
				bd->props.brightness);

	if (bl < 0 || bl > 255)
		return -EINVAL;

	mutex_lock(&lcd->lock);

	lcd->bl = bl;

	if (lcd->ldi_enable) {
		pr_debug("\n bl :%d\n", bl);
		update_brightness(lcd);
	}

	mutex_unlock(&lcd->lock);

	return 0;
}

const struct backlight_ops s5p_bl_ops = {
	.update_status = s5p_bl_update_status,
};

void tl2796_early_suspend(struct early_suspend *h)
{
	struct s5p_lcd *lcd = container_of(h, struct s5p_lcd,
								early_suspend);

	tl2796_ldi_disable(lcd);

	return ;
}
void tl2796_late_resume(struct early_suspend *h)
{
	struct s5p_lcd *lcd = container_of(h, struct s5p_lcd,
								early_suspend);

	tl2796_ldi_enable(lcd);

	return ;
}

static void seq_print_gamma_regs(struct seq_file *m, const u16 gamma_regs[])
{
	struct s5p_lcd *lcd = m->private;
	int c, i;
	const int adj_points[] = { 1, 19, 43, 87, 171, 255 };
	const char color[] = { 'R', 'G', 'B' };
	u8 brightness = lcd->bl;
	const struct tl2796_gamma_adj_points *bv = lcd->gamma_adj_points;
	const struct tl2796_gamma_reg_offsets *offset = &lcd->gamma_reg_offsets;

	for (c = 0; c < 3; c++) {
		// vt values are the direct result of gamma table lookups
		// for a given brightness level and an adjustement point

		// adj values correspond to what is sent to the the screen
		// for each adjustement points

		// v is ?

		u32 adj[6];
		u32 vt[6];
		u32 v[6];
		int scale = gamma_lookup(lcd, brightness, BV_0, c);

		vt[0] = gamma_lookup(lcd, brightness, bv->v1, c);
		vt[1] = gamma_lookup(lcd, brightness, bv->v19, c);
		vt[2] = gamma_lookup(lcd, brightness, bv->v43, c);
		vt[3] = gamma_lookup(lcd, brightness, bv->v87, c);
		vt[4] = gamma_lookup(lcd, brightness, bv->v171, c);
		vt[5] = gamma_lookup(lcd, brightness, bv->v255, c);

		adj[0] = gamma_regs[c] & 0xff;
		v[0] = DIV_ROUND_CLOSEST(
			(600 - 5 - adj[0] - offset->v[c][0]) * scale, 600);

		adj[5] = gamma_regs[3 * 5 + 2 * c] & 0xff;
		adj[5] = adj[5] << 8 | (gamma_regs[3 * 5 + 2 * c + 1] & 0xff);
		v[5] = DIV_ROUND_CLOSEST(
			(600 - 120 - adj[5] - offset->v[c][5]) * scale, 600);

		for (i = 4; i >= 1; i--) {
			adj[i] = gamma_regs[3 * i + c] & 0xff;
			v[i] = v[0] - DIV_ROUND_CLOSEST((v[0] - v[i + 1]) *
					(65 + adj[i] + offset->v[c][i]), 320);
		}
		seq_printf(m, "%c                   v0   %7d\n",
			   color[c], scale);
		for (i = 0; i < 6; i++) {
			seq_printf(m, "%c adj %3d (%02x) %+4d "
				   "v%-3d %7d - %7d %+8d\n",
				   color[c], adj[i], adj[i], offset->v[c][i],
				   adj_points[i], v[i], vt[i], v[i] - vt[i]);
		}
	}
}

static int tl2796_current_gamma_show(struct seq_file *m, void *unused)
{
	struct s5p_lcd *lcd = m->private;
	u16 gamma_regs[NUM_GAMMA_REGS];

	mutex_lock(&lcd->lock);
	setup_gamma_regs(lcd, gamma_regs);
	seq_printf(m, "brightness %3d:\n", lcd->bl);
	seq_print_gamma_regs(m, gamma_regs);
	mutex_unlock(&lcd->lock);
	return 0;
}

static int tl2796_current_gamma_open(struct inode *inode, struct file *file)
{
	return single_open(file, tl2796_current_gamma_show, inode->i_private);
}

static const struct file_operations tl2796_current_gamma_fops = {
	.open = tl2796_current_gamma_open,
	.read = seq_read,
	.release = single_release,
};

static void tl2796_parallel_read(struct s5p_lcd *lcd, u8 cmd,
				 u8 *data, size_t len)
{
	int i;
	struct s5p_panel_data *pdata = lcd->data;
	int delay = 10;

	gpio_set_value(pdata->gpio_dcx, 0);
	udelay(delay);
	gpio_set_value(pdata->gpio_wrx, 0);
	for (i = 0; i < 8; i++)
		gpio_direction_output(pdata->gpio_db[i], (cmd >> i) & 1);
	udelay(delay);
	gpio_set_value(pdata->gpio_wrx, 1);
	udelay(delay);
	gpio_set_value(pdata->gpio_dcx, 1);
	for (i = 0; i < 8; i++)
		gpio_direction_input(pdata->gpio_db[i]);

	udelay(delay);
	gpio_set_value(pdata->gpio_rdx, 0);
	udelay(delay);
	gpio_set_value(pdata->gpio_rdx, 1);
	udelay(delay);

	while (len--) {
		u8 d = 0;
		gpio_set_value(pdata->gpio_rdx, 0);
		udelay(delay);
		for (i = 0; i < 8; i++)
			d |= gpio_get_value(pdata->gpio_db[i]) << i;
		*data++ = d;
		gpio_set_value(pdata->gpio_rdx, 1);
		udelay(delay);
	}
	gpio_set_value(pdata->gpio_rdx, 1);
}

static int tl2796_parallel_setup_gpios(struct s5p_lcd *lcd, bool init)
{
	int ret;
	struct s5p_panel_data *pdata = lcd->data;

	if (!pdata->configure_mtp_gpios)
		return -EINVAL;

	if (init) {
		ret = pdata->configure_mtp_gpios(pdata, true);
		if (ret)
			return ret;

		gpio_direction_output(pdata->gpio_wrx, 1);
		gpio_direction_output(pdata->gpio_rdx, 1);
		gpio_direction_output(pdata->gpio_dcx, 0);
		gpio_direction_output(pdata->gpio_csx, 0);
	} else {
		gpio_set_value(pdata->gpio_csx, 1);
		pdata->configure_mtp_gpios(pdata, false);
	}
	return 0;
}

static u64 tl2796_voltage_lookup(struct s5p_lcd *lcd, int c, u32 v)
{
	int i;
	u32 vh = ~0, vl = ~0;
	u32 bl, bh = 0;
	u64 ret;
	struct s5p_panel_data *pdata = lcd->data;

	for (i = 0; i < pdata->gamma_table_size; i++) {
		vh = vl;
		vl = pdata->gamma_table[i].v[c];
		bh = bl;
		bl = pdata->gamma_table[i].brightness;
		if (vl <= v)
			break;
	}
	if (i == 0 || (v - vl) == 0) {
		ret = bl;
	} else {
		ret = (u64)bh * (s32)(v - vl) + (u64)bl * (vh - v);
		do_div(ret, vh - vl);
	}
	pr_debug("%s: looking for %7d c %d, "
		"found %7d:%7d, b %08x:%08x, ret %08llx\n",
		__func__, v, c, vl, vh, bl, bh, ret);
	return ret;
}

static void tl2796_adjust_brightness_from_mtp(struct s5p_lcd *lcd)
{
	int c;
	u32 v255[3];
	u64 bc[3];
	u64 bcmax;
	int shift;
	const struct tl2796_gamma_reg_offsets *offset = &lcd->gamma_reg_offsets;
	const u16 *factory_v255_regs = lcd->data->factory_v255_regs;

	for (c = 0; c < 3; c++) {
		int scale = gamma_lookup(lcd, 255, BV_0, c);
		v255[c] = DIV_ROUND_CLOSEST((600 - 120 - factory_v255_regs[c] -
						offset->v[c][5]) * scale, 600);
		// new in 2.3.3, read voltages from the screen hardware
		bc[c] = tl2796_voltage_lookup(lcd, c, v255[c]);
	}

	shift = lcd->data->color_adj.rshift;
	if (shift)
		for (c = 0; c < 3; c++)
			bc[c] = bc[c] * lcd->data->color_adj.mult[c] >> shift;

	bcmax = 0xffffffff;
	for (c = 0; c < 3; c++)
		if (bc[c] > bcmax)
			bcmax = bc[c];

	if (bcmax != 0xffffffff) {
		pr_warn("tl2796: factory calibration info is out of range: "
			"scale to 0x%llx\n", bcmax);
		bcmax += 1;
		shift = fls(bcmax >> 32);
		for (c = 0; c < 3; c++) {
			bc[c] <<= 32 - shift;
			do_div(bc[c], bcmax >> shift);
		}
	}

	for (c = 0; c < 3; c++) {
		lcd->color_mult[c] = bc[c];
		pr_info("tl2796: c%d, b-%08llx, got v %d, factory wants %d\n",
			c, bc[c], gamma_lookup(lcd, 255, BV_255, c), v255[c]);
	}
}

static s16 s9_to_s16(s16 v)
{
	return (s16)(v << 7) >> 7;
}

static void tl2796_read_mtp_info(struct s5p_lcd *lcd)
{
	int c, i;
	u8 data[21];
	u16 prepare_mtp_read[] = {
		/* LV2, LV3, MTP lock release code */
		0xf0, 0x15a, 0x15a,
		0xf1, 0x15a, 0x15a,
		0xfc, 0x15a, 0x15a,
		/* MTP cell enable */
		0xd1, 0x180,
		/* Sleep out */
		0x11,
		/* Sleep in  (start to read seq) */
		0x10,
		SLEEPMSEC, 40,

		ENDDEF, 0x0000
	};
	u16 start_mtp_read[] = {
		/* MPU  8bit read mode start */
		0xfc, 0x10c,

		ENDDEF, 0x0000
	};

	s6e63m0_panel_send_sequence(lcd, prepare_mtp_read);

	if (tl2796_parallel_setup_gpios(lcd, true)) {
		pr_err("%s: could not configure gpios\n", __func__);
		return;
	}

	s6e63m0_panel_send_sequence(lcd, start_mtp_read);

	tl2796_parallel_read(lcd, 0xd3, data, sizeof(data));

	for (c = 0; c < 3; c++) {
		for (i = 0; i < 5; i++)
			lcd->gamma_reg_offsets.v[c][i] = (s8)data[c * 7 + i];

		lcd->gamma_reg_offsets.v[c][5] =
			s9_to_s16(data[c * 7 + 5] << 8 | data[c * 7 + 6]);
	}

	tl2796_parallel_setup_gpios(lcd, false);

	tl2796_adjust_brightness_from_mtp(lcd);
}

static ssize_t min_brightness_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	return sprintf(buf, "%u\n", min_brightness);
}

static ssize_t min_brightness_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
	u32 value;
	if (sscanf(buf, "%u", &value) == 1)
	{
		min_brightness = value;
		update_brightness(lcd_);
	}
	return size;
}

static ssize_t brightness_multiplier_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	return sprintf(buf, "%u\n", bmult);
}

static ssize_t brightness_multiplier_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
	u8 value;
	if (sscanf(buf, "%u", &value) == 1)
	{
        bmult = (value < 1) ? 1 : value;
		update_brightness(lcd_);
	}
	return size;
}

static ssize_t red_multiplier_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	return sprintf(buf, "%u\n", lcd_->color_mult[0]);
}

static ssize_t red_multiplier_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
	u32 value;
	if (sscanf(buf, "%u", &value) == 1)
	{
		lcd_->color_mult[0] = value;
		update_brightness(lcd_);
	}
	return size;
}

static ssize_t green_multiplier_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	return sprintf(buf, "%u\n", lcd_->color_mult[1]);
}

static ssize_t green_multiplier_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
	u32 value;
	if (sscanf(buf, "%u", &value) == 1)
	{
		lcd_->color_mult[1] = value;
		update_brightness(lcd_);
	}
	return size;
}

static ssize_t blue_multiplier_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	return sprintf(buf, "%u\n", lcd_->color_mult[2]);
}

static ssize_t blue_multiplier_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
	u32 value;
	if (sscanf(buf, "%u", &value) == 1)
	{
		lcd_->color_mult[2] = value;
		update_brightness(lcd_);
	}
	return size;
}

static ssize_t gamma_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	return sprintf(buf, "%u\n", gamma);
}

static ssize_t gamma_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
	u8 value;
	if (sscanf(buf, "%u", &value) == 1)
	{
		gamma = value;
        hacky_v1_offset[0] = gamma * (-1);
        hacky_v1_offset[1] = gamma * (-1);
        hacky_v1_offset[2] = (gamma * (-1)) - 2;
		update_brightness(lcd_);
	}
	return size;
}

static DEVICE_ATTR(min_brightness, S_IRUGO | S_IWUGO, min_brightness_show, min_brightness_store);
static DEVICE_ATTR(brightness_multiplier, S_IRUGO | S_IWUGO, brightness_multiplier_show, brightness_multiplier_store);
static DEVICE_ATTR(gamma, S_IRUGO | S_IWUGO, gamma_show, gamma_store);
static DEVICE_ATTR(red_multiplier, S_IRUGO | S_IWUGO, red_multiplier_show, red_multiplier_store);
static DEVICE_ATTR(green_multiplier, S_IRUGO | S_IWUGO, green_multiplier_show, green_multiplier_store);
static DEVICE_ATTR(blue_multiplier, S_IRUGO | S_IWUGO, blue_multiplier_show, blue_multiplier_store);

static struct attribute *midnight_color_attributes[] = {
	&dev_attr_min_brightness.attr,
	&dev_attr_brightness_multiplier.attr,
	&dev_attr_gamma.attr,
	&dev_attr_red_multiplier.attr,
	&dev_attr_green_multiplier.attr,
	&dev_attr_blue_multiplier.attr,
	NULL
};

static struct attribute_group midnight_color_group = {
	.attrs = midnight_color_attributes,
};

static struct miscdevice midnight_color_device = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = "rgbb_multiplier",
};

static int __devinit tl2796_probe(struct spi_device *spi)
{
	struct s5p_lcd *lcd;
	int ret;
	int c;

	lcd = kzalloc(sizeof(struct s5p_lcd), GFP_KERNEL);
	if (!lcd) {
		pr_err("failed to allocate for lcd\n");
		ret = -ENOMEM;
		goto err_alloc;
	}
	mutex_init(&lcd->lock);

	spi->bits_per_word = 9;
	if (spi_setup(spi)) {
		pr_err("failed to setup spi\n");
		ret = -EINVAL;
		goto err_setup;
	}

	lcd->g_spi = spi;
	lcd->dev = &spi->dev;
	lcd->bl = 255;
	for (c = 0; c < 3; c++)
		lcd->color_mult[c] = 0xffffffff;

	if (!spi->dev.platform_data) {
		dev_err(lcd->dev, "failed to get platform data\n");
		ret = -EINVAL;
		goto err_setup;
	}
	lcd->data = (struct s5p_panel_data *)spi->dev.platform_data;

	if (!lcd->data->gamma_table || !lcd->data->seq_display_set ||
		!lcd->data->seq_etc_set || !lcd->data->standby_on ||
		!lcd->data->standby_off) {
		dev_err(lcd->dev, "Invalid platform data\n");
		ret = -EINVAL;
		goto err_setup;
	}
	lcd->gamma_adj_points =
		lcd->data->gamma_adj_points ?: &default_gamma_adj_points;

	spi_set_drvdata(spi, lcd);
	tl2796_read_mtp_info(lcd);

	lcd->bl_dev = backlight_device_register("s5p_bl",
			&spi->dev, lcd, &s5p_bl_ops, NULL);
	if (!lcd->bl_dev) {
		dev_err(lcd->dev, "failed to register backlight\n");
		ret = -EINVAL;
		goto err_setup;
	}

	lcd->bl_dev->props.max_brightness = 255;

	tl2796_ldi_enable(lcd);
#ifdef CONFIG_HAS_EARLYSUSPEND
	lcd->early_suspend.suspend = tl2796_early_suspend;
	lcd->early_suspend.resume = tl2796_late_resume;
	lcd->early_suspend.level = EARLY_SUSPEND_LEVEL_DISABLE_FB - 1;
	register_early_suspend(&lcd->early_suspend);
#endif

	lcd->debug_dir = debugfs_create_dir("s5p_bl", NULL);
	if (!lcd->debug_dir)
		dev_err(lcd->dev, "failed to create debug dir\n");
	else
		debugfs_create_file("current_gamma", S_IRUGO,
			lcd->debug_dir, lcd, &tl2796_current_gamma_fops);

	misc_register(&midnight_color_device);
	if (sysfs_create_group(&midnight_color_device.this_device->kobj, &midnight_color_group) < 0)
	{
		printk("%s sysfs_create_group fail\n", __FUNCTION__);
		pr_err("Failed to create sysfs group for device (%s)!\n", midnight_color_device.name);
	}

	// make a copy of the codec pointer
	lcd_ = lcd;

	pr_info("tl2796_probe successfully proved\n");

	return 0;

err_setup:
	mutex_destroy(&lcd->lock);
	kfree(lcd);

err_alloc:
	return ret;
}

static int __devexit tl2796_remove(struct spi_device *spi)
{
	struct s5p_lcd *lcd = spi_get_drvdata(spi);

	debugfs_remove_recursive(lcd->debug_dir);

	unregister_early_suspend(&lcd->early_suspend);

	backlight_device_unregister(lcd->bl_dev);

	tl2796_ldi_disable(lcd);

	kfree(lcd);

	return 0;
}

static struct spi_driver tl2796_driver = {
	.driver = {
		.name	= "tl2796",
		.owner	= THIS_MODULE,
	},
	.probe		= tl2796_probe,
	.remove		= __devexit_p(tl2796_remove),
};

static int __init tl2796_init(void)
{
	return spi_register_driver(&tl2796_driver);
}
static void __exit tl2796_exit(void)
{
	spi_unregister_driver(&tl2796_driver);
}

module_init(tl2796_init);
module_exit(tl2796_exit);

