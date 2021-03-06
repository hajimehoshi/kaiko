module kaiko.game.device;

private import std.conv;
private import std.utf;
private import std.windows.syserror;
private import win32.wingdi;
private import win32.windows;
private import win32.directx.d3d9;
private import win32.directx.d3dx9;
private import kaiko.game.color;
private import kaiko.game.colormatrix;
private import kaiko.game.geometrymatrix;
private import kaiko.game.texture;

align(4) struct D3DXIMAGE_INFO {
  UINT Width;
  UINT Height;
  UINT Depth;
  UINT MipLevels;
  D3DFORMAT Format;
  D3DRESOURCETYPE ResourceType;
  D3DXIMAGE_FILEFORMAT ImageFileFormat;
}

extern (Windows) {
  HRESULT D3DXGetImageInfoFromFileW(LPCWSTR pSrcFile, D3DXIMAGE_INFO* pSrcInfo);
}

private pure nothrow roundUp(int x) {
  immutable x2 = x - 1;
  immutable x3 = x2 | (x2 >> 1);
  immutable x4 = x3 | (x3 >> 2);
  immutable x5 = x4 | (x4 >> 4);
  immutable x6 = x5 | (x5 >> 8);
  immutable x7 = x6 | (x6 >> 16);
  return x6 + 1;
}

unittest {
  static assert(256 == roundUp(255));
  static assert(256 == roundUp(256));
  static assert(512 == roundUp(257));
}

final class Device {

  struct Vertex {
    float x, y, z;
    float tu, tv;
  }

  public final class TextureFactory(Texture_) {

    alias Texture_ Texture;

    private Device device_;

    invariant() {
      assert(this.device_ !is null);
    }

    private this(Device device) in {
      assert(device !is null);
    } body {
      this.device_ = device;
    }

    public Texture load(string path) in {
      assert(path !is null);
    } body {
      assert(std.file.exists(path)); // TODO: throw error
      IDirect3DTexture9 d3dTexture;
      {
        immutable result = D3DXCreateTextureFromFileExW(this.device_.d3dDevice_,
                                                        toUTF16z(path),
                                                        0,
                                                        0,
                                                        1,
                                                        0,
                                                        D3DFMT_A8R8G8B8,
                                                        D3DPOOL_DEFAULT,
                                                        D3DX_FILTER_NONE,
                                                        D3DX_DEFAULT,
                                                        0xff,
                                                        null,
                                                        null,
                                                        &d3dTexture);
        if (FAILED(result)) {
          throw new Exception("D3DXCreateTextureFromFileExW failed: " ~ std.conv.to!string(result));
        }
      }
      D3DXIMAGE_INFO imageInfo;
      D3DXGetImageInfoFromFileW(toUTF16z(path), &imageInfo);
      return new Texture(d3dTexture, imageInfo.Width, imageInfo.Height);
    }

  }

  private immutable int width_, height_;
  private immutable int textureWidth_, textureHeight_;
  private IDirect3D9 direct3D_;
  private IDirect3DDevice9 d3dDevice_;
  private IDirect3DTexture9 d3dOffscreenTexture_;
  private IDirect3DSurface9 d3dOffscreenSurface_;
  private IDirect3DSurface9 d3dBackBufferSurface_;
  private ID3DXEffect d3dxEffect_;
  private HANDLE hFont_;
  private TextureFactory!Texture textureFactory_;
  private GraphicsContext graphicsContext_;

  invariant() {
    assert(this.direct3D_);
    assert(this.d3dDevice_);
    assert(this.d3dOffscreenTexture_);
    assert(this.d3dOffscreenSurface_);
    assert(this.d3dBackBufferSurface_);
    assert(this.d3dxEffect_);
  }

  public this(HWND hWnd, int width, int height) in {
    assert(hWnd);
    assert(0 < width);
    assert(0 < height);
  } body {
    this.width_ = width;
    this.height_ = height;
    this.textureWidth_ = roundUp(width);
    this.textureHeight_ = roundUp(height);
    this.direct3D_ = Direct3DCreate9(D3D_SDK_VERSION);
    assert(this.direct3D_ !is null);
    D3DPRESENT_PARAMETERS presentParameters;
    with (presentParameters) {
      BackBufferFormat           = D3DFMT_UNKNOWN;
      BackBufferCount            = 1;
      MultiSampleType            = D3DMULTISAMPLE_NONE;
      MultiSampleQuality         = 0;
      SwapEffect                 = D3DSWAPEFFECT_DISCARD;
      hDeviceWindow              = hWnd;
      Windowed                   = true;
      EnableAutoDepthStencil     = false;
      AutoDepthStencilFormat     = D3DFMT_UNKNOWN;
      Flags                      = 0;
      FullScreen_RefreshRateInHz = 0;
      PresentationInterval       = D3DPRESENT_INTERVAL_ONE;
    }
    {
      if (FAILED(this.direct3D_.CreateDevice(D3DADAPTER_DEFAULT,
                                             D3DDEVTYPE_HAL,
                                             hWnd,
                                             D3DCREATE_HARDWARE_VERTEXPROCESSING,
                                             &presentParameters,
                                             &this.d3dDevice_))) {
        if (FAILED(this.direct3D_.CreateDevice(D3DADAPTER_DEFAULT,
                                               D3DDEVTYPE_HAL,
                                               hWnd,
                                               D3DCREATE_SOFTWARE_VERTEXPROCESSING,
                                               &presentParameters,
                                               &this.d3dDevice_))) {
          immutable result = this.direct3D_.CreateDevice(D3DADAPTER_DEFAULT,
                                                          D3DDEVTYPE_REF,
                                                          hWnd,
                                                          D3DCREATE_SOFTWARE_VERTEXPROCESSING,
                                                          &presentParameters,
                                                          &this.d3dDevice_);
          if (FAILED(result)) {
            throw new Exception("IDirect3D9.CreateDevice failed: " ~ to!string(result));
          }
        }
      }
    }
    assert(this.d3dDevice_);
    this.d3dDevice_.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
    this.d3dDevice_.SetRenderState(D3DRS_LIGHTING, false);
    this.d3dDevice_.SetRenderState(D3DRS_LOCALVIEWER, false);
    this.d3dDevice_.SetFVF(D3DFVF_XYZ | D3DFVF_TEX1);
    this.d3dDevice_.SetRenderState(D3DRS_ALPHABLENDENABLE, true);
    this.d3dDevice_.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
    this.d3dDevice_.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
    this.d3dDevice_.SetRenderState(D3DRS_COLORVERTEX, true);
    {
      D3DXMATRIX d3dxMatrix;
      D3DXMatrixIdentity(&d3dxMatrix);
      this.d3dDevice_.SetTransform(D3DTS_WORLDMATRIX(0), &d3dxMatrix);
      D3DXMatrixOrthoOffCenterLH(&d3dxMatrix, 0, this.textureWidth_, this.textureHeight_, 0, 0, 100);
      this.d3dDevice_.SetTransform(D3DTS_PROJECTION, &d3dxMatrix);
    }
    {
      immutable result = this.d3dDevice_.CreateTexture(this.textureWidth_,
                                                       this.textureHeight_,
                                                       1,
                                                       D3DUSAGE_RENDERTARGET,
                                                       D3DFMT_A8R8G8B8,
                                                       D3DPOOL_DEFAULT,
                                                       &this.d3dOffscreenTexture_,
                                                       null);
      if (FAILED(result)) {
        throw new Exception("IDirect3D9.CreateTexture failed: " ~ to!string(result));
      }
    }
    assert(this.d3dOffscreenTexture_);
    {
      immutable result = this.d3dOffscreenTexture_.GetSurfaceLevel(0,
                                                                   &this.d3dOffscreenSurface_);
      if (FAILED(result)) {
        throw new Exception("IDirect3DTexture9.GetSurfaceLevel failed: " ~ to!string(result));
      }
    }
    assert(this.d3dOffscreenSurface_);
    {
      immutable result = this.d3dDevice_.GetBackBuffer(0,
                                                       0,
                                                       D3DBACKBUFFER_TYPE_MONO,
                                                       &this.d3dBackBufferSurface_);
      if (FAILED(result)) {
        throw new Exception("IDirect3D9.GetBackBuffer failed: " ~ to!string(result));
      }
    }
    assert(this.d3dBackBufferSurface_);
    {
      auto shader = "
float4x4 ColorMatrix;
float4 ColorMatrixTranslation;
texture Texture;

sampler TextureSampler = sampler_state {
  Texture = <Texture>;
};

struct PixelIn {
  float2 TexUV : TEXCOORD0;
};

float4 PS(PixelIn p) : COLOR
{
  float4 color = tex2D(TextureSampler, p.TexUV);
  return mul(ColorMatrix, color) + ColorMatrixTranslation;
}

technique ColorMatrixFilter
{
  pass P0
  {
    PixelShader = compile ps_2_0 PS();
  }
}
".dup;
      ID3DXBuffer d3dxBuffer;
      immutable result = D3DXCreateEffect(this.d3dDevice_,
                                          shader.ptr,
                                          shader.length,
                                          null,
                                          null,
                                          0,
                                          null,
                                          &this.d3dxEffect_,
                                          &d3dxBuffer);
      if (FAILED(result)) {
        if (d3dxBuffer.GetBufferSize()) {
          const errorStrPtr = cast(char*)d3dxBuffer.GetBufferPointer();
          immutable len = d3dxBuffer.GetBufferSize();
          string errorStr;
          errorStr ~= errorStrPtr[0..len];
          throw new Exception("D3DXCreateEffect failed: " ~ errorStr);
        } else {
          throw new Exception("D3DXCreateEffect failed: " ~ to!string(result));
        }
      }
    }
    assert(this.d3dxEffect_);
    {
      auto techniqueName = "ColorMatrixFilter\0".dup;
      immutable result = this.d3dxEffect_.SetTechnique(techniqueName.ptr);
      if (FAILED(result)) {
        throw new Exception("IDirect3DEffect9.SetTechnique failed: " ~ to!string(result));
      }
    }
    {
      immutable fontResourceSrc = FindResource(null, toUTF16z("FONT"), toUTF16z("DATA"));
      assert(fontResourceSrc);
      immutable fontResource = LoadResource(null, fontResourceSrc);
      assert(fontResource);
      auto fontImage = LockResource(fontResource);
      assert(fontImage);
      immutable fontImageSize = SizeofResource(null, fontResourceSrc);
      assert(fontImageSize);
      DWORD fontCount = 0;
      this.hFont_ = AddFontMemResourceEx(fontImage, fontImageSize, null, &fontCount);
      assert(this.hFont_);
      assert(fontCount);
    }
  }

  ~this() {
    if (this.hFont_) {
      RemoveFontMemResourceEx(this.hFont_);
      this.hFont_ = null;
    }
    if (this.d3dxEffect_ !is null) {
      this.d3dxEffect_.Release();
      this.d3dxEffect_ = null;
    }
    if (this.d3dBackBufferSurface_ !is null) {
      this.d3dBackBufferSurface_.Release();
      this.d3dBackBufferSurface_ = null;
    }
    if (this.d3dOffscreenSurface_ !is null) {
      this.d3dOffscreenSurface_.Release();
      this.d3dOffscreenSurface_ = null;
    }
    if (this.d3dOffscreenTexture_ !is null) {
      this.d3dOffscreenTexture_.Release();
      this.d3dOffscreenTexture_ = null;
    }
    if (this.d3dDevice_ !is null) {
      this.d3dDevice_.Release();
      this.d3dDevice_ = null;
    }
    if (this.direct3D_ !is null) {
      this.direct3D_.Release();
      this.direct3D_ = null;
    }
  }

  @property
  public GraphicsContext graphicsContext() out(result) {
    assert(result !is null);
  } body {
    if (!this.graphicsContext_) {
      this.graphicsContext_ = new GraphicsContext(this);
    }
    return this.graphicsContext_;
  }

  @property
  public TextureFactory!Texture textureFactory() out(result) {
    assert(result !is null);
  } body {
    if (!this.textureFactory_) {
      this.textureFactory_ = new TextureFactory!Texture(this);
    }
    return this.textureFactory_;
  }

  public void update(Drawable)(Drawable drawable) in {
    assert(drawable);
  } body {
    this.d3dDevice_.Clear(0, null, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0, 0, 0), 1.0f, 0);
    scope (exit) { this.d3dDevice_.Present(null, null, null, null); }
    {
      this.d3dDevice_.BeginScene();
      scope (exit) { this.d3dDevice_.EndScene(); }
      {
        this.d3dDevice_.SetRenderTarget(0, this.d3dOffscreenSurface_);
        scope (exit) { this.d3dDevice_.SetRenderTarget(0, this.d3dBackBufferSurface_); }
        this.d3dDevice_.Clear(0, null, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0, 0, 0), 1.0f, 0);
        drawable.draw(this.graphicsContext);
      }
      {
        RECT sourceRect = { 0, 0, this.width_, this.height_ };
        RECT destRect   = { 0, 0, this.width_ * 2, this.height_ * 2 };
        this.d3dDevice_.StretchRect(this.d3dOffscreenSurface_,
                                    &sourceRect,
                                    this.d3dBackBufferSurface_,
                                    &destRect,
                                    D3DTEXF_POINT);
      }
    }
  }

  private final class GraphicsContext {

    private Device device_;
    private ID3DXFont d3dxFont_;

    invariant() {
      assert(this.device_ !is null);
    }

    private this(Device device) in {
      assert(device !is null);
    } body {
      this.device_ = device;
      {
        immutable result = D3DXCreateFontW(this.device_.d3dDevice_,
                                           13, // 11 or 13
                                           6, // 5 or 6
                                           FW_NORMAL,
                                           1,
                                           false,
                                           DEFAULT_CHARSET,
                                           OUT_DEFAULT_PRECIS,
                                           DEFAULT_QUALITY,
                                           DEFAULT_PITCH | FF_SCRIPT,
                                           toUTF16z("BDF M+"),
                                           &this.d3dxFont_);
        if (FAILED(result)) {
          throw new Exception("D3DXCreateFont failed: " ~ to!string(result));
        }
      }
    }
    
    ~this() {
      if (this.d3dxFont_) {
        this.d3dxFont_.Release();
        this.d3dxFont_ = null;
      }
    }

    public void drawTexture(Texture)(in Texture texture,
                                     ref const(GeometryMatrix) geometryMatrix,
                                     int z,
                                     ref const(ColorMatrix) colorMatrix) in {
      assert(std.math.isFinite(geometryMatrix.a));
      assert(std.math.isFinite(geometryMatrix.b));
      assert(std.math.isFinite(geometryMatrix.c));
      assert(std.math.isFinite(geometryMatrix.d));
      assert(std.math.isFinite(geometryMatrix.tx));
      assert(std.math.isFinite(geometryMatrix.ty));
      foreach (i; 0..4) {
        foreach (j; 0..5) {
          assert(std.math.isFinite(colorMatrix[i, j]));
        }
      }
    } body {
      {
        auto valName = "Texture\0".dup;
        this.device_.d3dxEffect_.SetTexture(valName.ptr, texture.lowerTexture);
      }
      {
        auto valName = "ColorMatrix\0".dup;
        D3DXMATRIX d3dxMatrix;
        // TODO: use mixin
        with (d3dxMatrix) {
          _11 = colorMatrix[0, 0];
          _12 = colorMatrix[0, 1];
          _13 = colorMatrix[0, 2];
          _14 = colorMatrix[0, 3];
          _21 = colorMatrix[1, 0];
          _22 = colorMatrix[1, 1];
          _23 = colorMatrix[1, 2];
          _24 = colorMatrix[1, 3];
          _31 = colorMatrix[2, 0];
          _32 = colorMatrix[2, 1];
          _33 = colorMatrix[2, 2];
          _34 = colorMatrix[2, 3];
          _41 = colorMatrix[3, 0];
          _42 = colorMatrix[3, 1];
          _43 = colorMatrix[3, 2];
          _44 = colorMatrix[3, 3];
        }
        this.device_.d3dxEffect_.SetMatrix(valName.ptr, &d3dxMatrix);
      }
      {
        auto valName = "ColorMatrixTranslation\0".dup;
        float[] values = [colorMatrix[0, 4],
                          colorMatrix[1, 4],
                          colorMatrix[2, 4],
                          colorMatrix[3, 4]];
        this.device_.d3dxEffect_.SetFloatArray(valName.ptr, values.ptr, values.length);
      }
      this.device_.d3dxEffect_.Begin(null, 0);
      scope (exit) { this.device_.d3dxEffect_.End(); }
      this.device_.d3dxEffect_.BeginPass(0);
      scope (exit) { this.device_.d3dxEffect_.EndPass(); }
      immutable width  = texture.width;
      immutable height = texture.height;
      immutable tu     = cast(float)texture.width  / texture.textureWidth;
      immutable tv     = cast(float)texture.height / texture.textureHeight;
      D3DXMATRIX d3dxMatrix;
      with (d3dxMatrix) {
        _11 = geometryMatrix.a;
        _12 = geometryMatrix.c;
        _13 = 0; _14 = 0;
        _21 = geometryMatrix.b;
        _22 = geometryMatrix.d;
        _23 = 0; _24 = 0;
        _31 = 0; _32 = 0; _33 = 1; _34 = 0;
        _41 = geometryMatrix.tx;
        _42 = geometryMatrix.ty;
        _43 = 0; _44 = 1;
      }
      this.device_.d3dDevice_.SetTransform(D3DTS_VIEW, &d3dxMatrix);
      Vertex[4] vertices = [{ 0,     0,      z, 0,  0,  },
                            { width, 0,      z, tu, 0,  },
                            { 0,     height, z, 0,  tv, },
                            { width, height, z, tu, tv, }];
      this.device_.d3dDevice_.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, vertices.ptr, typeof(vertices[0]).sizeof);
    }

    public void drawText(string text, int x, int y, Color color) {
      if (!text.length) {
        return;
      }
      immutable utf16Text = toUTF16(text);
      RECT rect = { x, y, 0, 0 };
      this.d3dxFont_.DrawTextW(null, utf16Text.ptr, utf16Text.length, &rect,
                               win32.directx.d3dx9.DT_CALCRECT,
                               0);
      this.d3dxFont_.DrawTextW(null, utf16Text.ptr, utf16Text.length, &rect,
                               win32.directx.d3dx9.DT_LEFT | win32.directx.d3dx9.DT_BOTTOM,
                               D3DCOLOR_ARGB(color.alpha, color.red, color.green, color.blue));
    }

  }

}
