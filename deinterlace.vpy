import vapoursynth as vs
import havsfunc as haf  # https://github.com/HomeOfVapourSynthEvolution/havsfunc

core = vs.get_core(threads = 1)

# ffms2.Source skips frames, so use an external ffmpeg to decode and read
# the raw y4m file.
clip = core.raws.Source(source = '/tmp/input.y4m')

# TR2 - Temporal linear smoothing radius used for final stablization / denoising. Increase for smoother output. Default is 2.
# SourceMatch 0 = Source-matching off (standard algorithm), 1 = basic source-match, 2 = refined match, 3 = twice refined match
# Lossless mode 1 restores the *exact* pixels of the source into the output
# NoiseProcess=0 => disable denoising
# Sharpness=0.0 => disable sharpening
clip = haf.QTGMC(clip, Preset="Very Slow", TFF=True, SourceMatch=3, TR2=0, Lossless=1, NoiseProcess=0, Sharpness=0.0)

clip.set_output()
