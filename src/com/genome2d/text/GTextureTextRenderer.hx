package com.genome2d.text;
import com.genome2d.components.renderable.text.GText;
import com.genome2d.debug.GDebug;
import com.genome2d.input.GMouseInput;
import com.genome2d.input.GMouseInputType;
import com.genome2d.textures.GTexture;
import com.genome2d.textures.GTextureManager;
import com.genome2d.utils.GHAlignType;
import com.genome2d.utils.GVAlignType;
import com.genome2d.context.IGContext;
import com.genome2d.context.GCamera;
import flash.display.BitmapData;
class GTextureTextRenderer extends GTextRenderer {

    private var g2d_fontScale:Float = 1;
    #if swc @:extern #end
    public var fontScale(get, set):Float;
    #if swc @:getter(fontScale) #end
    inline private function get_fontScale():Float {
        return g2d_fontScale;
    }
    #if swc @:setter(fontScale) #end
    inline private function set_fontScale(p_value:Float):Float {
        g2d_fontScale = p_value;
        g2d_dirty = true;
        return g2d_fontScale;
    }

    private var g2d_textureFont:GTextureFont;
    #if swc @:extern #end
    public var textureFont(get, set):GTextureFont;
    #if swc @:getter(textureFont) #end
    inline private function get_textureFont():GTextureFont{
        return g2d_textureFont;
    }
    #if swc @:setter(textureFont) #end
    inline private function set_textureFont(p_value:GTextureFont):GTextureFont {
        g2d_textureFont = p_value;
        g2d_dirty = true;
        return g2d_textureFont;
    }

    private var g2d_chars:Array<GTextureCharRenderable>;
	
	private var g2d_cursorBlinkCount:Int = 0;
	
	public var cursorStartIndex:Int = 0;
	public var cursorEndIndex:Int = 0;
	private var g2d_cursorCurrentIndex:Int = 0;
	
	static private var g2d_helperTexture:GTexture;
	
	public function new():Void {
		super();
		
		if (g2d_helperTexture == null) {
			g2d_helperTexture = GTextureManager.createTexture("GTextureTextRenderer_helper", new BitmapData(4, 4, false, 0xFFFFFF));
			g2d_helperTexture.pivotX = g2d_helperTexture.pivotY = -2;
		}
	}

    override public function render(p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float):Void {
        if (g2d_textureFont == null) return;
        if (g2d_dirty) invalidate();
		
		if (input) renderSelection(p_x, p_y, p_scaleX, p_scaleY, 0);

        var charCount:Int = g2d_chars.length;
        var cos:Float = 1;
        var sin:Float = 0;
        if (p_rotation != 0) {
            cos = Math.cos(p_rotation);
            sin = Math.sin(p_rotation);
        }

		var tx:Float;
        var ty:Float;
		
        for (i in 0...charCount) {
            var renderable:GTextureCharRenderable = g2d_chars[i];
            if (!renderable.g2d_visible) break;
			if (renderable.g2d_whiteSpace) continue;
			
			var cx:Float = renderable.g2d_x + renderable.g2d_char.xoffset;
			var cy:Float = renderable.g2d_y + renderable.g2d_char.yoffset;

            if (p_rotation != 0) {
                tx = (cx * cos - cy * sin) * p_scaleX * g2d_fontScale + p_x;
                ty = (cy * cos + cx * sin) * p_scaleY * g2d_fontScale + p_y;
            } else {
				tx = cx * p_scaleX * g2d_fontScale + p_x;
				ty = cy * p_scaleY * g2d_fontScale + p_y;
			}
			
			g2d_context.draw(renderable.g2d_char.texture, tx, ty, p_scaleX * g2d_fontScale, p_scaleY * g2d_fontScale, p_rotation, 1, 1, 1, 1, 1, null);
        }
	}
	
	private function renderSelection(p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float):Void {
		g2d_cursorBlinkCount++;
		if (cursorStartIndex == cursorEndIndex && Std.int(g2d_cursorBlinkCount / 10) % 2 == 0) {
			var tx:Float = p_x;
			var ty:Float = p_y;
			if (g2d_textLength > 0) { 
				var char:GTextureCharRenderable = (cursorEndIndex >= g2d_textLength) ? g2d_chars[g2d_textLength - 1] : g2d_chars[cursorEndIndex];
				tx = char.g2d_x * p_scaleX * g2d_fontScale + p_x + (cursorStartIndex>=g2d_textLength?char.g2d_char.xadvance + g2d_tracking:0);
				ty = char.g2d_y * p_scaleY * g2d_fontScale + p_y;
			}
			var char:GTextureChar = g2d_textureFont.getCharById(Std.string(124));
			g2d_context.draw(char.texture, tx, ty, p_scaleX * g2d_fontScale, p_scaleY * g2d_fontScale, p_rotation, 1, 1, 1, 1, 1, null);
		} else if (cursorStartIndex != cursorEndIndex) {
			var startChar:GTextureCharRenderable = (cursorStartIndex >= g2d_textLength) ? g2d_chars[g2d_textLength - 1] : g2d_chars[cursorStartIndex];
			var sx:Float = startChar.g2d_x * p_scaleX * g2d_fontScale + p_x + (cursorStartIndex >= g2d_textLength?startChar.g2d_char.xadvance + g2d_tracking:0);
			var sy:Float = startChar.g2d_y * p_scaleY * g2d_fontScale + p_y;
			
			var endChar:GTextureCharRenderable = (cursorEndIndex >= g2d_textLength) ? g2d_chars[g2d_textLength - 1] : g2d_chars[cursorEndIndex];
			var ex:Float = endChar.g2d_x * p_scaleX * g2d_fontScale + p_x + (cursorEndIndex >= g2d_textLength? endChar.g2d_char.xadvance + g2d_tracking:0);
			var ey:Float = endChar.g2d_y * p_scaleY * g2d_fontScale + p_y;
			
			if (sy == ey) {
				g2d_context.draw(g2d_helperTexture, sx, sy, (ex-sx)/4*p_scaleX * g2d_fontScale, g2d_textureFont.lineHeight/4*p_scaleY * g2d_fontScale, p_rotation, 1, 1, 1, 1, 1, null);
			} else {
				g2d_context.draw(g2d_helperTexture, sx, sy, (g2d_width + p_x - sx) / 4 * p_scaleX * g2d_fontScale, g2d_textureFont.lineHeight / 4 * p_scaleY * g2d_fontScale, p_rotation, 1, 1, 1, 1, 1, null);
				for (i in 1...Std.int((ey - sy) / g2d_textureFont.lineHeight)) {
					g2d_context.draw(g2d_helperTexture, p_x, sy+i*g2d_textureFont.lineHeight, g2d_width / 4 * p_scaleX * g2d_fontScale, g2d_textureFont.lineHeight / 4 * p_scaleY * g2d_fontScale, p_rotation, 1, 1, 1, 1, 1, null);
				}
				g2d_context.draw(g2d_helperTexture, p_x, ey, (ex - p_x) / 4 * p_scaleX * g2d_fontScale, g2d_textureFont.lineHeight / 4 * p_scaleY * g2d_fontScale, p_rotation, 1, 1, 1, 1, 1, null);
			}
		}
	}

    override public function invalidate():Void {
        if (g2d_chars == null) g2d_chars = new Array<GTextureCharRenderable>();
        if (g2d_textureFont == null) return;

        if (g2d_autoSize) {
            g2d_width = 0;
        }

        var offsetX:Float = 0;
        var offsetY:Float =  0;
        var renderable:GTextureCharRenderable;
        var char:GTextureChar = null;
        var currentCharCode:Int = -1;
        var previousCharCode:Int = -1;
        var lastChar:Int = 0;

        var lines:Array<Array<GTextureCharRenderable>> = new Array<Array<GTextureCharRenderable>>();
        var currentLine:Array<GTextureCharRenderable> = new Array<GTextureCharRenderable>();
        var charIndex:Int = 0;
        var whiteSpaceIndex:Int = -1;
        var i:Int = 0;

        while (i < g2d_textLength) {
			if (charIndex>=g2d_chars.length) {
				renderable = new GTextureCharRenderable();
				g2d_chars.push(renderable);
			} else {
				renderable = g2d_chars[charIndex];
			}
			
            // New line character
            if (g2d_text.charCodeAt(i) == 10 || g2d_text.charCodeAt(i) == 13) {
                if (g2d_autoSize) {
                    g2d_width = (offsetX>g2d_width) ? offsetX : g2d_width;
                }
                previousCharCode = -1;
                lines.push(currentLine);
                currentLine = new Array<GTextureCharRenderable>();
                if (!g2d_autoSize && offsetY + 2*(g2d_textureFont.lineHeight + g2d_lineSpace) > g2d_height/g2d_fontScale) break;
                offsetX = 0;
                offsetY += g2d_textureFont.lineHeight + g2d_lineSpace;
				
				renderable.g2d_x = offsetX;
				renderable.g2d_y = offsetY;
				renderable.g2d_whiteSpace = true;
				charIndex++;
            } else {
                if (!g2d_autoSize && offsetY + g2d_textureFont.lineHeight + g2d_lineSpace > g2d_height / g2d_fontScale) break;

                currentCharCode = g2d_text.charCodeAt(i);
                char = g2d_textureFont.getCharById(Std.string(currentCharCode));

                if (char == null) {
                    GDebug.warning("Texture for character " + g2d_text.charAt(i) + " with code " + g2d_text.charCodeAt(i) + " not found!");
					i++;
                    continue;
                }

                if (previousCharCode != -1) {
                    offsetX += g2d_textureFont.getKerning(previousCharCode,currentCharCode);
                }

				renderable.g2d_code = currentCharCode;
				renderable.g2d_char = char;

				if (!g2d_autoSize && offsetX + char.texture.width > g2d_width / g2d_fontScale) {
					lines.push(currentLine);
					var backtrack:Int = i - whiteSpaceIndex - 1;
					var currentCount:Int = currentLine.length;
					currentLine.splice(currentLine.length - backtrack, backtrack);
					currentLine = new Array<GTextureCharRenderable>();
					charIndex -= backtrack;

					if (backtrack >= currentCount) break;
					if (!g2d_autoSize && offsetY + 2 * (g2d_textureFont.lineHeight + g2d_lineSpace) > g2d_height / g2d_fontScale) break;

					i = whiteSpaceIndex+1;
					offsetX = 0;
					offsetY += g2d_textureFont.lineHeight + g2d_lineSpace;
					continue;
				}

				currentLine.push(renderable);
				renderable.g2d_visible = true;
				renderable.g2d_x = offsetX;
				renderable.g2d_y = offsetY;
				charIndex++;
				
				if (currentCharCode == 32) {
					whiteSpaceIndex = i;
					renderable.g2d_whiteSpace = true;
				} else {
					renderable.g2d_whiteSpace = false;
				}

                offsetX += char.xadvance + g2d_tracking;

                previousCharCode = currentCharCode;
            }
            ++i;
        }
        lines.push(currentLine);

        var charCount:Int = g2d_chars.length;
        for (i in charIndex...charCount) {
            g2d_chars[i].g2d_visible = false;
        }

        if (g2d_autoSize) {
            g2d_width = (offsetX>g2d_width) ? offsetX : g2d_width;
            g2d_height = offsetY + g2d_textureFont.lineHeight;
        }

        var bottom:Float = offsetY + g2d_textureFont.lineHeight;
        var offsetY:Float = 0;
        if (g2d_vAlign == GVAlignType.MIDDLE) {
            offsetY = (g2d_height - bottom) * .5;
        } else if (g2d_vAlign == GVAlignType.BOTTOM) {
            offsetY = g2d_height - bottom;
        }

        for (i in 0...lines.length) {
            var currentLine:Array<GTextureCharRenderable> = lines[i];

            charCount = currentLine.length;
            if (charCount == 0) continue;
            var offsetX:Float = 0;
            var last:GTextureCharRenderable = currentLine[charCount-1];
            var right:Float = last.g2d_x - last.g2d_char.xoffset + last.g2d_char.xadvance;

            if (g2d_hAlign == GHAlignType.CENTER) {
                offsetX = (g2d_width - right) * .5;
           } else if (g2d_hAlign == GHAlignType.RIGHT) {
                offsetX = g2d_width - right;
            }

            for (j in 0...charCount) {
                var renderable:GTextureCharRenderable = currentLine[j];
                renderable.g2d_x = renderable.g2d_x + offsetX;
                renderable.g2d_y = renderable.g2d_y + offsetY;
            }
        }

        g2d_dirty = false;
    }
	
	private function getCharAt(p_x:Float, p_y:Float):Int {
		var minX:Float = Math.POSITIVE_INFINITY;
		var minY:Float = Math.POSITIVE_INFINITY;
		var charCount:Int = g2d_chars.length;
		var minIndex:Int = charCount;
		for (i in 0...charCount) {
			var char:GTextureCharRenderable = g2d_chars[i];
			if (!char.g2d_visible) break;

			var tx:Float = char.g2d_x * g2d_fontScale;
			var ty:Float = char.g2d_y * g2d_fontScale;
			
			var difX:Float = p_x - tx;
			if (difX < 0) continue;
			var difY:Float = p_y - ty;
			if (difY < -char.g2d_char.yoffset * g2d_fontScale) continue;
			if (difX < minX && difY < g2d_textureFont.lineHeight * g2d_fontScale) {
				minX = difX;
				minY = difY;
				minIndex = i;
			}
		}
		
		if (minIndex<charCount && minX > g2d_fontScale*g2d_chars[minIndex].g2d_char.texture.width / 2) minIndex++;
		
		return minIndex;
	}
	
	public function captureMouseInput(p_input:GMouseInput):Void {
		var index:Int = getCharAt(p_input.localX, p_input.localY);
		if (p_input.type == GMouseInputType.MOUSE_DOWN) {
			g2d_cursorCurrentIndex = cursorEndIndex = cursorStartIndex = index;
			trace(g2d_cursorCurrentIndex);
		} else if (p_input.type == GMouseInputType.MOUSE_MOVE && p_input.buttonDown) {
			if (index < g2d_cursorCurrentIndex) {
				cursorStartIndex = index;
				cursorEndIndex = g2d_cursorCurrentIndex;
			} else {
				cursorStartIndex = g2d_cursorCurrentIndex;
				cursorEndIndex = index;
			}
		}
	}
}

@:allow(com.genome2d.text.GTextureTextRenderer)
class GTextureCharRenderable
{
    private var g2d_code:Int;
    private var g2d_char:GTextureChar;

    private var g2d_x:Float;
    private var g2d_y:Float;

	private var g2d_whiteSpace:Bool = false;
    private var g2d_visible:Bool = false;

    public function new() {
    }
}
