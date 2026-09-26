import React from 'react';
import {Composition} from 'remotion';
import './brand';
import {FPS} from './brand';
import {OVERVIEW_FRAMES, Overview} from './videos/Overview';
import {ON_PAPER_FRAMES, OnPaper} from './videos/OnPaper';
import {PARENTS_FRAMES, Parents} from './videos/Parents';

export const RemotionRoot: React.FC = () => (
  <>
    {/* 16:9 for the website and LinkedIn. */}
    <Composition id="Overview" component={Overview} durationInFrames={OVERVIEW_FRAMES} fps={FPS} width={1920} height={1080} />
    {/* Square for the LinkedIn feed. */}
    <Composition id="OnPaper" component={OnPaper} durationInFrames={ON_PAPER_FRAMES} fps={FPS} width={1080} height={1080} />
    <Composition id="Parents" component={Parents} durationInFrames={PARENTS_FRAMES} fps={FPS} width={1080} height={1080} />
  </>
);
