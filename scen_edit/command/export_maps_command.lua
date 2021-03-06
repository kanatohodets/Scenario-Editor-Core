ExportMapsCommand = AbstractCommand:extends{}
ExportMapsCommand.className = "ExportMapsCommand"

function ExportMapsCommand:init(path)
    self.className = "ExportMapsCommand"
    self.path = path
end

local shaderObj
function ExportMapsCommand:GetShaderObj()
    local heightmapScaleShader = [[
        uniform sampler2D heightmapTex;
        uniform float groundMin, groundMax;
        void main() {
            gl_FragColor = texture2D(heightmapTex, gl_TexCoord[0].st);
            gl_FragColor.rgb = (gl_FragColor.rgb - groundMin) / (groundMax - groundMin);
        }
    ]]

    local shader = gl.CreateShader({
        fragment = heightmapScaleShader,
        uniformInt = {heightmapTexID = 0 },
    })
    local errors = gl.GetShaderLog(shader)
    if errors ~= "" then
        Spring.Echo(errors)
    end
    shaderObj = {
        shader = shader,
        uniforms = {
            heightmapTexID = gl.GetUniformLocation(shader, "heightmapTex"),
            groundMaxID    = gl.GetUniformLocation(shader, "groundMax"),
            groundMinID    = gl.GetUniformLocation(shader, "groundMin"),
        }
    }
    return shaderObj
end

function ExportMapsCommand:execute()
    SCEN_EDIT.delayGL(function()
        -- create dir just to be sure
        Spring.CreateDir(self.path)

        -- heightmap
        local heightmapPath = self.path .. "/heightmap.png"

        Spring.Echo("Saving the heightmap to " .. heightmapPath .. "...")

        if VFS.FileExists(heightmapPath, VFS.RAW) then
            Spring.Echo("removing the existing heightmap")
            os.remove(heightmapPath)
        end

        local texInfo = gl.TextureInfo("$heightmap")
        local GL_LUMINANCE32F_ARB = 0x8818
        local heightmapTexture = gl.CreateTexture(texInfo.xsize, texInfo.ysize, {
            format = GL_LUMINANCE32F_ARB,
            border = false,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST,
            wrap_s = GL.CLAMP_TO_EDGE,
            wrap_t = GL.CLAMP_TO_EDGE,
            fbo = true,
        })

        -- not used, seem incorrect
        local minHeight, maxHeight = Spring.GetGroundExtremes()
        Spring.Echo(maxHeight, minHeight)

        local maxH, minH = -math.huge, math.huge
        for x = 0, Game.mapSizeX, Game.squareSize do
            for z = 0, Game.mapSizeZ, Game.squareSize do
                local groundHeight = Spring.GetGroundHeight(x, z)
                if groundHeight > maxH then
                    maxH = groundHeight
                end
                if groundHeight < minH then
                    minH = groundHeight
                end
            end
        end
        Spring.Echo(minH, maxH)

        local shaderObj = self:GetShaderObj()
        gl.UseShader(shaderObj.shader)
        gl.Uniform(shaderObj.uniforms.groundMaxID, maxH)
        gl.Uniform(shaderObj.uniforms.groundMinID, minH)
        gl.Texture(0, "$heightmap")
        gl.RenderToTexture(heightmapTexture,
        function()
            gl.TexRect(-1,-1, 1, 1)
        end)
        gl.Texture(0, false)
        gl.UseShader(0)

        gl.RenderToTexture(heightmapTexture, gl.SaveImage, 0, 0, texInfo.xsize, texInfo.ysize, heightmapPath, {grayscale16bit = true})
        gl.DeleteTexture(heightmapTexture)

        -- grass
        local grassPath = self.path .. "/grass.png"
        Spring.Echo("Saving the grass to " .. grassPath .. "...")

        if VFS.FileExists(grassPath, VFS.RAW) then
            Spring.Echo("removing the existing grass")
            os.remove(grassPath)
        end

        local texInfo = gl.TextureInfo("$grass")
        local grassTexture = gl.CreateTexture(texInfo.xsize, texInfo.ysize, {
            border = false,
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP_TO_EDGE,
            wrap_t = GL.CLAMP_TO_EDGE,
            fbo = true,
        })

        gl.Texture("$grass")
        gl.RenderToTexture(grassTexture,
        function()
            gl.TexRect(-1,-1, 1, 1)
        end)
        gl.Texture(false)

        gl.RenderToTexture(grassTexture, gl.SaveImage, 0, 0, texInfo.xsize, texInfo.ysize, grassPath)
        gl.DeleteTexture(grassTexture)

        -- diffuse
        local texturePath = self.path .. "/texture.png"
 
        if VFS.FileExists(texturePath, VFS.RAW) then
            Spring.Echo("removing the existing texture")
            os.remove(texturePath)
        end

        Spring.Echo("Saving the texture to " .. texturePath .. "...")
        local totalMapTexture = gl.CreateTexture(Game.mapSizeX, Game.mapSizeZ, {
            border = false,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST,
            wrap_s = GL.CLAMP_TO_EDGE,
            wrap_t = GL.CLAMP_TO_EDGE,
            fbo = true,
        })
        local totalMapFBO = gl.CreateFBO({
            color0 = totalMapTexture
        })
        local texSize = SCEN_EDIT.model.textureManager.TEXTURE_SIZE
        local sizeX = math.floor(Game.mapSizeX / texSize)
        local sizeZ = math.floor(Game.mapSizeZ / texSize)
        local mapFBO
        for i = 0, sizeX do
            for j = 0, sizeZ do
                local mapTextureObj = SCEN_EDIT.model.textureManager.mapFBOTextures[i][j]

                local mapTexture = mapTextureObj.texture
                mapFBO = gl.CreateFBO({
                    color0 = mapTexture
                })
                gl.BlitFBO(
                    mapFBO, 0, 0, texSize, texSize,
                    totalMapFBO, i * texSize, (sizeZ - j) * texSize, (i + 1) * texSize, (sizeZ - j - 1) * texSize)
                gl.DeleteFBO(mapFBO)
            end
        end
        -- Either blitting isn't working, or FBOs aren't properly mapped to textures...?
        gl.RenderToTexture(totalMapTexture, gl.SaveImage, 0, 0, Game.mapSizeX, Game.mapSizeZ, texturePath)
        gl.DeleteTexture(totalMapTexture)
        -- FIXME: probably not needed -.-
        gl.Flush()
    end)
end
