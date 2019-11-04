# Audio Container and Codec
<b>Audio Container</b> is describing the format of the audio file itself<br>
The actual audio data inside can be encoded many different ways

## Audio Encoding
- AAC
  * <b>AAC</b> means "Advanced Audio Coding", was designed to be the successor of MP3
  * compresses the original sound, resulting in disk savings but lower quality
  * The loss of quality is not always noticeable depending on bit rate
  * AAC does better compression than MP3
- HE-AAC
  * Superset of AAC, <b>HE</b> means "high efficiency"
  * Optimized for low bit rate audio such as streaming audio
- AMR
  * <b>AMR</b> means "Adaptive Multi-Rate"
  * Optimized for speech, featuring very low bit rates
- ALAC
  * Knowns as "Apple Lossless"
  * Encoding the compresses the audio data without losing any quality
- iLBC
  * Another optimized for speech
  * Good for voice over IP, and streaming audio
- IMA4
  * Compression format that gives you 4:1 compression on 16-bit audio files
- linear PCM
  * Technique used to convert analog sound data into a digital format
  * In Simple terms just means uncompressed data
  * If the data is uncompressed, it is the fastest to play when space is not an issue
- μ-law and a-law
  * Another alternate encoding to convert analog data into digital
- MP3
  * Very popular audio container
  
## Audio Container
- MPEG-1(.mp3)
- MPEG_2 ADTS(.aac)
- AIFF
- CAF
- WAVE

# Bit Rates
- The bit rate of an audio file is the number of bits that are processed per unit of time, usually expressed as bits per second(bit/s) or (kbit/s)<br>
- Higher bit rates produce larger files
- When you lower the bit rate, lose quality as well

## Most Common bit rates
- 32kbit/s  : AM Radio quality
- 48kbit/s  : Common rate for long speech podcasts
- 64kbit/s  : Common rate for normal-length speech podcasts
- 96kbit/s  : FM Radio quality
- 128kbit/s : Most common bit rate for MP3 music
- 160kbit/s : Musicians or sensitive listeners prefer this to 128kbit/s
- 192kbit/s : Digital radio broadcasting quality
- 320kbit/s : Virtually indistinguishable from CDs
- 500kbit/s-1,411kbit/s : Lossless audio encoding such as linear PCM
  
# Sample Rates
When converting an analog signal to digital format, the sample rate is how often the sound wave is sampled to make a digital signal