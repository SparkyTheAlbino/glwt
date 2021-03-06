//
//  Window.mm
//  glwt
//
//  Created by Alex Parker on 07/01/2013.
//  Copyright (c) 2013 Alex Parker. All rights reserved.
//

#include "glwt.h"
#import "GLView.h"
#import "AppDelegate.h"
#include <string>
#include <sstream>

NSWindow* window = nil;
int gWidth, gHeight;

bool Window::Open(int width, int height, bool fullscreen, const char* windowTitle)
{
    NSRect screenSize = [[NSScreen mainScreen] frame];
    
    NSRect mainDisplayRect = NSMakeRect((screenSize.size.width-width)/2, (screenSize.size.height-height)/2, width, height);
    window = [[NSWindow alloc]
                        initWithContentRect: mainDisplayRect
                        styleMask: NSClosableWindowMask|NSResizableWindowMask|NSMiniaturizableWindowMask|NSTitledWindowMask
                        backing:NSBackingStoreBuffered
                        defer:YES];
    [window setTitle:[NSString stringWithUTF8String:windowTitle]];
    [window setOpaque:YES];
    [window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    
    if (fullscreen)
        [window toggleFullScreen:nil];
   
    //Request an OpenGL 3.2 context (bleurgh... horrible. wtf apple)
    CGLPixelFormatAttribute attribs[] =
    {
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
        kCGLPFAAccelerated,
        kCGLPFANoRecovery,
        kCGLPFAColorSize, (CGLPixelFormatAttribute)24,
        kCGLPFADepthSize, (CGLPixelFormatAttribute)16,
        kCGLPFADoubleBuffer,
        (CGLPixelFormatAttribute)0
    };
    CGLPixelFormatObj cglPixelFormat = NULL;
    GLint numPixelFormats;
    CGLChoosePixelFormat (attribs, &cglPixelFormat, &numPixelFormats);
    
    NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithCGLPixelFormatObj:cglPixelFormat];
    NSRect viewRect = NSMakeRect(0.0, 0.0, mainDisplayRect.size.width, mainDisplayRect.size.height);
    GLView *fullScreenView = [[GLView alloc] initWithFrame:viewRect pixelFormat: pixelFormat];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [[fullScreenView openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    //Load Open GL functions
    if (GL::Init() != 0)
    {
        std::stringstream errMsg;
        const Version& version = GL::GetVersion();
        errMsg << "Unsupported version of OpenGL (" << version.major << "." << version.minor << "). Please upgrade your graphics drivers.";
        Window::ShowMessageBox(errMsg.str().c_str());
        return false;
    }
    
    //Add the OpenGL view to the window
    [window setContentView: fullScreenView];
    [window makeKeyAndOrderFront:[AppDelegate delegate]];
    
    fullScreenView->openGLReady = true;
    
    return true;
}

void Window::Close()
{
    [[NSApplication sharedApplication] terminate:nil];
}

int Window::Width()
{
    return window != nil ? [[window contentView] bounds].size.width : 0;
}

int Window::Height()
{
    return window != nil ? [[window contentView] bounds].size.height : 0;
}

void Window::ShowMessageBox(const char *message)
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:[NSString stringWithUTF8String:message]];
    [alert runModal];
}

