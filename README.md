# Reverse Image Search - a Safari App Extension

This Safari extension allows reverse image searches (aka "search by image" or "search using an image") directly from a web page.  When you come across an image on any website, just right-click it to open a context menu, and select "Search with Google", etc. to run a search for other instances of the target image, or to find similar images. 

This extension is intended to replace legacy reverse image search extensions that were disabled by Safari 12's move to the app extension model.

## Installation

1.  Download and run the containing app "ReverseImageSearch.app".  On Github, download from the [Releases tab](https://github.com/yimingliu/reverse-image-search-safari/releases) of the repository if a release is available (if not available, open an issue on Github -- I probably just forgot to make a build).   

2.  Go into `Safari -> Preferences -> Extensions` and activate the Reverse Image Search extension.  

3.  Reload the current active page to allow the injected script to take effect.

The containing app can be used to configure the supported search engines.

For the extension to work, it obviously requires access to all websites being visited, in order to retrieve images.  Apple (rightfully) warns that giving this permission means the extension can read any data, on any website being visited.  Users paranoid about allowing this level of access can read the source code, to see that nothing nefarious is happening.

If you prefer to compile from source (to be absolutely sure that nothing nefarious is happening), check out the repository and compile the project with XCode as normal.  Note that it is going to require an Apple Developer certificate for code-signing.

## Usage

Right-click on most images on a web page, and pick "Search with Google", "Search with Bing", etc.  If the page allows direct image hotlinking from Google or Bing, this should redirect to the reverse image search results.

## Compatibility

Tested on macOS 10.15.2 Catalina and Safari 13.0.4.  It may or may not work with other combinations of {macOS, Safari} versions, as I can only test on my own personal machine.

The build target is now set for macOS 10.13.  Unfortunately, I do not have a macOS 10.13 machine to test with, so if it turns out to not work on 10.13, I cannot offer support.  I will take patches or pull requests, however.

## Future work

* Add other image search engines (feel free to propose new search engines in the Github issues)

* If the site in question does not allow Google/Bing direct access to images, proxy the request by downloading the image and then POST'ing it to the image search endpoint.  This might be difficult since the app extension itself does not share session with the current running browser instance, and the image might be too large for message-passing. 


## Disclaimer

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
