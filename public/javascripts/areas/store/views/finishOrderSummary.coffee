define [
  'jquery'
  'underscore'
  'backboneConfig'
  'handlebars'
  '../models/products'
  '../models/cart'
  '../models/orders'
  '../models/order'
  'text!./templates/finishOrderSummary.html'
  './cartItem'
  '../../../converters'
], ($, _, Backbone, Handlebars, Products, Cart, Orders, Order, finishOrderSummaryTemplate, CartItemView, converters) ->
  class FinishOrderPayment extends Backbone.Open.View
    events:
      'click #finishOrder':'finishOrder'
      'click #backToStore': -> Backbone.history.navigate('', true)
      'click #goBackToPayment': -> Backbone.history.navigate('finishOrder/payment', true)
    template: finishOrderSummaryTemplate
    initialize: (opt) =>
      @store = opt.store
      @cart = opt.cart
      @user = opt.user
    render: =>
      unless @cart.shippingCalculated()
        return Backbone.history.navigate 'finishOrder/shipping', trigger: true
      context = Handlebars.compile @template
      numberOfProducts = @cart.items().length
      shippingCost = converters.currency @cart.shippingCost()
      orderSummary =
        shippingCost: shippingCost
        productsInfo: "#{numberOfProducts} produto#{if numberOfProducts > 1 then 's' else ''}"
        totalProductsPrice: converters.currency @cart.totalPrice()
        totalSaleAmount: converters.currency @cart.totalSaleAmount()
      viewModel = user: @user, cart: @cart, store: @store, orderSummary: orderSummary, paymentType: @cart.paymentTypeSelected(), directSell: @cart.paymentTypeSelected().type is 'directSell', hasShipping: @cart.hasShipping()
      if @cart.hasShipping()
        viewModel.shippingOption = @cart.shippingOptionSelected()
        viewModel.shippingOptionPlural = viewModel.shippingOption.days > 1
      @$el.html context viewModel
      super
    finishOrder: ->
      $("#finishOrder").prop "disabled", on
      items = _.map @cart.items(), (i) -> _id: i._id, quantity: i.quantity
      orders = new Orders storeId: @store._id
      paymentType = @cart.paymentTypeSelected().type
      success = (model, response, opt) =>
        @cart.clear()
        if @store.pagseguro and paymentType is 'pagseguro'
          window.location = response.redirect
        else
          Backbone.history.navigate 'finishOrder/orderFinished', trigger: true
      error = (model, xhr, opt) =>
        @logXhrError 'store', xhr
        @showDialogError "Não foi possível fazer o pedido. Tente novamente mais tarde."
        $("#finishOrder").prop "disabled", off
      order = items: items
      if @cart.hasShipping()
        order.shippingType = @cart.shippingOptionSelected().type
      order.paymentType = paymentType
      order = new Order order
      orders.add order
      order.save order.attributes, error: error, success: success
