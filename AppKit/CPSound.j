/*
 * CPSound.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2010, Antoine Mercadal
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>

CPSoundLoadStateEmpty       = 0;
CPSoundLoadStateLoading     = 1;
CPSoundLoadStateCanBePlayed = 2;
CPSoundLoadStateError       = 3;

CPSoundPlayBackStatePlay    = 0;
CPSoundPlayBackStateStop    = 1;
CPSoundPlayBackStatePause   = 2;


/*!
    CPSound provides a way to load and play sounds. In the browser it relies on the
    HTML5 audio tag being available.

    CPSound delegate:
        - sound:didFinishPlaying: called when sound has finished to played

*/
@implementation CPSound : CPObject
{
    CPString            _name       @accessors(property=name);
    id                  _delegate   @accessors(property=delegate);

    BOOL                _playRequestBeforeLoad;
    HTMLAudioElement    _audioTag;
    int                 _loadStatus;
    int                 _playBackStatus;
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
    if (self = [super init])
    {
        _loadStatus = CPSoundLoadStateEmpty;
//        _loops = NO;
        _audioTag = document.createElement("audio");
        _audioTag.preload = YES;
        _playRequestBeforeLoad = NO;

        _audioTag.addEventListener("canplay", function()
        {
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            [self _soundDidload];
        }, true);

        _audioTag.addEventListener("ended", function()
        {
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            [self _soundDidEnd];
        }, true);

        _audioTag.addEventListener("error", function()
        {
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            [self _soundError];
        }, true);
    }

    return self;
}

/*!
    Initialize with the sound contents of the URL represented by aFile.

    @param aFile CPString the path of the sound
    @param byRef ignored (Cocoa compatibility)
*/
- (id)initWithContentsOfFile:(CPString)aFile byReference:(BOOL)byRef
{
    if (self = [self init])
    {
        _loadStatus = CPSoundLoadStateLoading;
        _audioTag.src = aFile;
    }

    return self;
}

/*!
    Initialize with the sound contents of the file located at aURL.

    @param aURL CPURL containing the URL of the sound
    @param byRef ignored (Cocoa compatibility)
*/
- (id)initWithContentsOfURL:(CPURL)aURL byReference:(BOOL)byRef
{
    return [self initWithContentsOfFile:[aURL absoluteString] byReference:NO];
}

/*!
    Initialize with the sound contents of someData.

    @param someData CPData containing the sound
    @param byRef ignored (Cocoa compatibility)
*/
- (id)initWithData:(CPData)someData
{
    if (self = [self init])
    {
        _loadStatus = CPSoundLoadStateLoading;
        _audioTag.src = [someData rawString];
    }

    return self;
}


#pragma mark -
#pragma mark Events listener

/*! @ignore
*/
- (void)_soundDidload
{
    _loadStatus = CPSoundLoadStateCanBePlayed;

    if (_playRequestBeforeLoad)
    {
        _playRequestBeforeLoad = NO;
        [self play];
    }
}

/*! @ignore
*/
- (void)_soundDidEnd
{
    if (![self loops])
        [self stop];
}

/*! @ignore
*/
- (void)_soundError
{
    _loadStatus = CPSoundLoadStateError;
    CPLog.error("Cannot load sound. Maybe the format of your sound is not compatible with your browser.");
}


#pragma mark -
#pragma mark Media controls

/*!
    Play the sound.

    @return YES when the receiver is playing its audio data, NO otherwise.
*/
- (BOOL)play
{
    if (_loadStatus === CPSoundLoadStateLoading)
    {
        _playRequestBeforeLoad = YES;
        return YES;
    }

    if ((_loadStatus !== CPSoundLoadStateCanBePlayed)
        || (_playBackStatus === CPSoundPlayBackStatePlay))
        return NO;

    _audioTag.play();
    _playBackStatus = CPSoundPlayBackStatePlay;

    return YES;
}

/*!
    Stop the sound.

    @return YES when the receiver is playing its audio data, NO otherwise.
*/
- (BOOL)stop
{
    if ((_loadStatus !== CPSoundLoadStateCanBePlayed)
        || (_playBackStatus === CPSoundPlayBackStateStop))
        return NO;

    _audioTag.pause();
    _audioTag.currentTime = 0.0;
    _playBackStatus = CPSoundPlayBackStateStop;

    if (_delegate && [_delegate respondsToSelector:@selector(sound:didFinishPlaying:)])
        [_delegate sound:self didFinishPlaying:YES];

    return YES;
}

/*!
    Pause the sound.

    @return YES when the receiver is playing its audio data, NO otherwise.
*/
- (BOOL)pause
{
    if ((_loadStatus !== CPSoundLoadStateCanBePlayed)
        || (_playBackStatus === CPSoundPlayBackStatePause))
        return NO;

    _audioTag.pause();
    _playBackStatus = CPSoundPlayBackStatePause;

    return YES;
}

/*!
    Resume playback of a paused sound.

    @return YES when the receiver is playing its audio data, NO otherwise.
*/
- (BOOL)resume
{
    if ((_loadStatus !== CPSoundLoadStateCanBePlayed)
        || (_playBackStatus !== CPSoundPlayBackStatePause))
        return NO;

    _audioTag.play();
    _playBackStatus = CPSoundPlayBackStatePlay;

    return YES;
}

/*!
    Return YES if the sound is in loop mode.

    @return BOOL YES if in loop mode, NO otherwise
*/
- (BOOL)loops
{
    return _audioTag.loop;
}

/*!
    Specifies whether the sound should repeat.

    @param BOOL YES for loop mode, NO otherwise
*/
- (void)setLoops:(BOOL)shouldLoop
{
    _audioTag.loop = shouldLoop;
}

/*!
    Returns the volume of the receiver.

    @return double from 0.0 to 1.0
*/
- (double)volume
{
    return _audioTag.volume;
}

/*!
    Set the volume the sound should be played at.

    @param double a volume value between 0.0 and 1.0
*/
- (void)setVolume:(double)aVolume
{
    if (aVolume > 1.0)
        aVolume = 1.0;
    else if (aVolume < 0.0)
        aVolume = 0.0;

    _audioTag.volume = aVolume;
}

#pragma mark -
#pragma mark Accessors

/*!
    Returns the duration in seconds of the sound.

    @return double the duration
*/
- (double)duration
{
    return _audioTag.duration;
}

/*!
    Returns if the sound is playing or not.

    @return BOOL YES if the sound is playing, NO otherwise
*/
- (BOOL)isPlaying
{
    return (_playBackStatus === CPSoundPlayBackStatePlay);
}

@end
