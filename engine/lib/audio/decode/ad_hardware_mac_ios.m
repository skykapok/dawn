#include "../oal_decode.h"

#include <stdbool.h>

#ifdef SUPPORT_AUDIO_HARDWARE_MAC_IOS
#import <AVFoundation/AVFoundation.h>

@class ADAudioSource;
static ADAudioSource* _instance = nil;

@interface ADAudioSource : NSObject <AVAudioPlayerDelegate> {
  AVAudioPlayer* _source_player;
  NSString* _source_filepath;
  float _volume;
  bool _loop;
  bool _isplaying;
}

@property (readonly) bool isload;
@end

@implementation ADAudioSource

-(id) init {
  if((self = [super init])) {
    _source_filepath = nil;
    _source_player = nil;
    _loop = false;
    _isplaying = false;
  }
  return self;
}

-(bool)isload {
  return _source_player != nil;
}


+(id) sharedInstance {
  if(!_instance) {
    _instance = [[ADAudioSource alloc] init];
//      NSError* error = nil;
//      [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&error];
//      assert(error==nil);
  }
  return _instance;
}

-(bool) load:(NSString*) filepath {
  if(_source_filepath == nil || ![filepath isEqualToString:_source_filepath]) {
    _source_filepath = [filepath copy];
    NSError *error = nil;
    if(_isplaying){
      [self stop];
    }
    _source_player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:_source_filepath] error:&error];
    
    if(error == nil) {
      _source_player.delegate = self;
      [_source_player prepareToPlay];
    }else {
      NSString* err = [NSString stringWithFormat:@"load %@ error[%@]", filepath, error];
      ad_error([err UTF8String]);
      return false;
    }
  }
  return true;
}


-(void)loop:(bool) v {
  _loop = v;
}

-(void) play {
  [_source_player play];
  _isplaying = true;
}


-(void) stop {
  _isplaying = false;
  [_source_player stop];
}

-(void) pause {
  _isplaying = false;
  [_source_player pause];
}

-(void)setVolume:(float) volume {
  _source_player.volume = volume;
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  NSLog(@"audioPlayerDidFinishPlaying %d", flag);
  _isplaying = false;
  if(_loop) {
    [self play];
  }
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
  // nothing todo it.
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
  if(_isplaying) {
    [self play];
  }
}
@end

static int
l_load(lua_State* L) {
  const char* filepath = lua_tostring(L, 1);
  bool success = [[ADAudioSource sharedInstance] load:[NSString stringWithFormat:@"%s", filepath]];
  if(!success) {
    luaL_error(L, ad_last_error());
  }
  return 0;
}

static int
l_play(lua_State* L) {
  bool loop = lua_toboolean(L, 1);
  ADAudioSource* source = [ADAudioSource sharedInstance];
  if([source isload]){
    [source loop:loop];
    [source play];
  }
  return 0;
}

static int
l_stop(lua_State* L) {
  ADAudioSource* source = [ADAudioSource sharedInstance];
  if([source isload]){
    [source stop];
  }
  return 0;
}

static int
l_pause(lua_State* L) {
 ADAudioSource* source = [ADAudioSource sharedInstance];
  if([source isload]){
    [source pause];
  }
  return 0; 
}


int
adl_decode_hardware_ios(lua_State* L) {
  luaL_checkversion(L);
  luaL_Reg l[] = {
    {"load", l_load},
    {"play", l_play},
    {"stop", l_stop},
    {"pause", l_pause},
    {NULL, NULL},
  };
  
  luaL_newlib(L, l);
  return 1;
}

#else

// no support hardware decode ios
int
adl_decode_hardware_ios(lua_State* L) {
  lua_pushboolean(L, false);
  return 1;
}

#endif


