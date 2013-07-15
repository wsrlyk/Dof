//-----------------------------------------------------------------------------
// Copyright (c) 2007 dhpoware. All Rights Reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//-----------------------------------------------------------------------------
//
// This demo shows you how to import Alias|Wavefront OBJ and MTL files into
// your OpenGL applications. The OBJ file format is one of the most widely
// supported 3D file formats. All of the most popular 3D content creation
// packages includes support for this file format either natively or through
// third party plugins.
//
// Models are rendered using either the fixed function pipeline or the
// programmable pipeline. The fixed function pipeline is used on hardware that
// only supports OpenGL 1.x. The programmable pipeline is used on hardware that
// supports OpenGL 2.0 and higher. The supported GLSL shaders are per fragment
// Blinn-Phong and normal Mapping. Both support only a single fixed directional
// light source shining down the OpenGL default negative z-axis.
//
// Most of the time the per fragment Blinn-Phong shader will be used. The
// normal mapping shader will be used only when the OBJ model's MTL file
// includes a material that has a bump map (specified using the 'map_bump'
// command). This demo assumes that any bump map associated with a material
// will be a normal map. All other bump map formats are not supported.
//
// When the MTL file contains a material with a normal map this demo will
// generate smooth tangent vectors for the OBJ model. The smooth tangent
// vectors are generated by summing the triangle face tangent vectors of
// adjacent triangle faces and then normalizing the resulting tangent vector.
// The bitangent vectors are not generated here. They are calculated in the
// normal mapping shader's vertex shader.
//
// A minimal file menu is provided to enable OBJ files to be loaded at runtime.
// The demo includes drag and drop support for OBJ files. Drop an OBJ file onto
// the demo's window and the OBJ file will be loaded. Alternatively drop the
// OBJ file onto the demo's EXE file. The demo will launch and load the OBJ
// file.
//
// This demo is completely self contained. The two GLSL shaders are embedded
// into the demo's EXE file as resources.
//
// Left click and drag using the mouse to translate the model.
// Middle click and drag using the mouse to zoom in and out of the model.
// Right click and drag using the mouse to rotate the model.
//
//-----------------------------------------------------------------------------
#pragma once
#if !defined(WIN32_LEAN_AND_MEAN)
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>
#include "GLSLProgramObject.h"
#include <commdlg.h>	// for open file dialog box
#include <shellapi.h>   // for drag and drop support

#include <GL/gl.h>
#include <GL/glu.h>
#include <cassert>
#include <cmath>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#if defined(_DEBUG)
#include <crtdbg.h>
#endif

#include "bitmap.h"
//#include "gl2.h"
#include "model_obj.h"
#include "resource.h"
#include "WGL_ARB_multisample.h"
#include "SkyBox.h"
#include "stdio.h"
#include "stdlib.h"
//-----------------------------------------------------------------------------
// Constants.
//-----------------------------------------------------------------------------

#define APP_TITLE "OpenGL OBJ Viewer"

// Windows Vista compositing support.
#if !defined(PFD_SUPPORT_COMPOSITION)
#define PFD_SUPPORT_COMPOSITION 0x00008000
#endif

// GL_EXT_texture_filter_anisotropic
#define GL_TEXTURE_MAX_ANISOTROPY_EXT     0x84FE
#define GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT 0x84FF

#define CAMERA_FOVY  30.0f
#define CAMERA_ZFAR  200.0f
#define CAMERA_ZNEAR 0.1f

#define MOUSE_ORBIT_SPEED 0.30f     // 0 = SLOWEST, 1 = FASTEST
#define MOUSE_DOLLY_SPEED 0.02f     // same as above...but much more sensitive
#define MOUSE_TRACK_SPEED 0.005f    // same as above...but much more sensitive

//-----------------------------------------------------------------------------
// Type definitions.
//-----------------------------------------------------------------------------

typedef std::map<std::string, GLuint> ModelTextures;

//-----------------------------------------------------------------------------
// Globals.
//-----------------------------------------------------------------------------

HWND                g_hWnd;
HDC                 g_hDC;
HGLRC               g_hRC;
HINSTANCE           g_hInstance;
int                 g_framesPerSecond;
float                 g_windowWidth;
float                 g_windowHeight;
float					g_windowWidthRate = 0.5;
float					g_windowHeightRate = 0.5;
int                 g_msaaSamples;
GLuint              g_nullTexture;
GLuint              g_blinnPhongShader;
GLuint              g_normalMappingShader;
float               g_maxAnisotrophy;
/*			hotel
float               g_heading = -169.8;//-153.3;//-48;
float               g_pitch = -6.3;//1.8;//29;
float               g_cameraPos[3] = {0.454, 0.159, 2.2};
float               g_targetPos[3] = {0.454, 0.159,0};//{-0.835, -0.145, 0};
float				g_clickPosX = 412;//512;//331;//413;
float				g_clickPosY = 166;//147;//194;//119;
*/
/*			keting
float               g_heading = -338;//-153.3;//-48;
float               g_pitch = -2.4;//1.8;//29;
float               g_cameraPos[3] = {-0.32, 0.11, 0.66};
float               g_targetPos[3] = {-0.32, 0.11,0};//{-0.835, -0.145, 0};
float				g_clickPosX = 185;//512;//331;//413;
float				g_clickPosY = 143;//147;//194;//119;
*/
/*			beautiworld
*/
float               g_heading = -153.3;//-48;
float               g_pitch = 1.8;//29;
float               g_cameraPos[3] = {-0.61,-0.19,3.78};//{-0.835, -0.145, 3.78};
float               g_targetPos[3] = {-0.61,-0.19,0};//{-0.835, -0.145, 0};
float				g_clickPosX = 282;//331;//413;
float				g_clickPosY = 206;//194;//119;

bool                g_isFullScreen;
bool                g_hasFocus;
bool                g_enableWireframe;
bool                g_enableTextures = true;
bool                g_supportsProgrammablePipeline;
bool                g_cullBackFaces = true;

float				g_skyColor[3] = {0.48, 0.64, 0.96};
//float				g_skyColor[3] = {0.86, 0.86, 0.84};
bool				g_click = false;
ModelOBJ            g_model;
ModelTextures       g_modelTextures;

GLSLProgramObject blinnphong_program;
GLSLProgramObject g_shaderAverageInit;
GLSLProgramObject g_shaderAverageFinal;
GLuint g_accumulationTexId[2];
GLuint g_accumulationFboId;

// front peeling
GLSLProgramObject g_shaderFrontBackground;
GLSLProgramObject g_shaderFrontInit;
GLSLProgramObject g_shaderFrontPeel;
GLSLProgramObject g_shaderFrontCalcCoc;
GLSLProgramObject g_shaderFrontFinal;

GLuint g_frontFboId[2];
GLuint g_frontDepthTexId[2];
GLuint g_frontColorTexId[2];
GLuint g_frontColorBlenderTexId;
GLuint g_frontColorBlenderFboId;
GLuint g_frontCocTexId;
GLuint g_frontCocFboId;
GLuint g_frontRealDepthTexId;
GLuint g_frontBackgroundFboId;
GLuint g_frontSkyboxTexId[6];

int currId;
int prevId;

// ds
GLSLProgramObject g_shaderDsDecomposition;
GLSLProgramObject g_shaderDsBluring;

GLuint g_dsFboId;
GLuint g_dsLayerTexId;
GLuint g_dsLayerFboId;

//////////////////////////////////////////////////////////////////////////
GLuint g_vboId;
GLuint g_eboId;
float g_white[3] = {1.0,1.0,1.0};
float g_black[3] = {0.0};
float g_green[3] = {0.3, 0.3, 0.7};
float *g_backgroundColor = g_green;
float g_opacity = 0.6;
GLenum g_drawBuffers[] = {GL_COLOR_ATTACHMENT0_EXT,
	GL_COLOR_ATTACHMENT1_EXT,
	GL_COLOR_ATTACHMENT2_EXT,
	GL_COLOR_ATTACHMENT3_EXT,
	GL_COLOR_ATTACHMENT4_EXT,
	GL_COLOR_ATTACHMENT5_EXT,
	GL_COLOR_ATTACHMENT6_EXT
};
GLuint g_quadDisplayList;
//-----------------------------------------------------------------------------
// Functions Prototypes.
//-----------------------------------------------------------------------------

void    Cleanup();
void    CleanupApp();
GLuint  CompileShader(GLenum type, const GLchar *pszSource, GLint length);
HWND    CreateAppWindow(const WNDCLASSEX &wcl, const char *pszTitle);
GLuint  CreateNullTexture(int width, int height);
void    DrawFrame();
void    DrawModelUsingFixedFuncPipeline();
void    DrawModelUsingProgrammablePipeline();
bool    ExtensionSupported(const char *pszExtensionName);
float   GetElapsedTimeInSeconds();
bool    Init();
void    InitApp();
void    InitGL();
GLuint  LinkShaders(GLuint vertShader, GLuint fragShader);
void    LoadModel(const char *pszFilename);
GLuint  LoadShaderProgramFromResource(const char *pResouceId, std::string &infoLog);
GLuint  LoadTexture(const char *pszFilename);
void    Log(const char *pszMessage);
void    ProcessMenu(HWND hWnd, WPARAM wParam, LPARAM lParam);
void    ProcessMouseInput(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);
void    ReadTextFileFromResource(const char *pResouceId, std::string &buffer);
void    ResetCamera();
void    SetProcessorAffinity();
void    ToggleFullScreen();
void    UnloadModel();
void    UpdateFrame(float elapsedTimeSec);
void    UpdateFrameRate(float elapsedTimeSec);
LRESULT CALLBACK WindowProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

#define SHADER_PATH "content//shaders//"
void InitAccumulationRenderTargets();
void InitFrontPeelingRenderTargets();
void InitDsRenderTargets();
void BuildShaders();
void MakeFullScreenQuad();
void RenderAverageColors();
void RenderFrontToBackPeeling();
void DrawModel(int step);

void preFor(int step);
void postFor(int step);

void preModel(int step, const ModelOBJ::Mesh *pMesh);
void postModel(int step);

void RenderAccumulationBuffer();
void RenderDavidSchedl();
