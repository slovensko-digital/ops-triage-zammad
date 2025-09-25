class App.TicketZoomArticleImageView extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Download')
  buttonClass: 'btn--success'
  head: ''
  dynamicSize: true

  elements:
    '.imagePreview-image': 'imageContainer'
    '.js-nav-left':        'navLeftButton'
    '.js-nav-right':       'navRightButton'

  events:
    'submit form':      'submit'
    'click .js-cancel': 'cancel'
    'click .js-close':  'cancel'
    'click .js-nav-left':  'nextLeft'
    'click .js-nav-right': 'nextRight'

  constructor: ->
    super
    @unbindAll()
    $(document).on('keydown.image_preview', (e) =>
      return @nextRight() if e.keyCode is 39 # right
      return @nextLeft() if e.keyCode is 37 # left
    )

  updateNavigation: =>
    @navLeftButton.toggleClass('is-invisible', !@hasPrevious())
    @navRightButton.toggleClass('is-invisible', !@hasNext())

  hasPrevious: ->
    @parentElement.closest('.attachment').prev('.attachment.attachment--preview').length > 0

  hasNext: ->
    @parentElement.closest('.attachment').next('.attachment.attachment--preview').length > 0

  updateImage: (newImageElement, newParentElement) =>
    @updateNavigation()

    newImageSrc = newImageElement.attr('src').replace(/view=preview/, 'view=inline')

    preloader = new Image()
    preloader.onload = =>
      @image = newImageElement.get(0).outerHTML
      @parentElement = newParentElement

      @imageContainer.velocity { opacity: 0 }, {
        duration: 100
        complete: =>
          @imageContainer.html(preloader)
          @updateNavigation()
          @imageContainer.velocity { opacity: 1 }, { duration: 100 }
      }

    preloader.onerror = =>
      @updateNavigation()
      @imageContainer.html("<div class='alert alert--danger'>#{@T('Failed to load image.')}</div>")

    preloader.src = newImageSrc


  nextRight: =>
    nextElement = @parentElement.closest('.attachment').next('.attachment.attachment--preview')
    return if nextElement.length is 0

    @updateImage(nextElement.find('img'), nextElement)

  nextLeft: =>
    prevElement = @parentElement.closest('.attachment').prev('.attachment.attachment--preview')
    return if prevElement.length is 0

    @updateImage(prevElement.find('img'), prevElement)

  content: ->
    imageSrc = @image.replace(/view=preview/, 'view=inline')
    """
    <div class="centered imagePreview">
      <div class="imagePreview-nav js-nav-left">#{App.Utils.icon('arrow-left')}</div>
      <div class="imagePreview-image">#{imageSrc}</div>
      <div class="imagePreview-nav js-nav-right">#{App.Utils.icon('arrow-right')}</div>
    </div>
    """

  onSubmit: =>
    currentImageSrc = @imageContainer.find('img').attr('src')
    return if !currentImageSrc
    url = "#{currentImageSrc.replace(/(\?|)view=(preview|inline)/, '')}?disposition=attachment"
    window.open(url, '_blank')

  onShow: =>
    @el.attr('tabindex', '-1')
    $('.modal').focus()
    @updateNavigation()

  onClose: =>
    @unbindAll()

  unbindAll: ->
    $(document).off('keydown.image_preview')
