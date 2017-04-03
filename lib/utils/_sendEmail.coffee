_         = require 'lodash'
request   = require '@arangodb/request'
util      = require 'util'
_         = require 'lodash'


{mailApikey}  = module.context.configuration
{mailBcc}     = module.context.configuration
{mailTitle}   = module.context.configuration
{mailFrom}    = module.context.configuration

SPARKPOST_API = 'https://api.sparkpost.com/api'
SPARKPOST_NAMESPACE = 'v1'
SPARKPOST_COMMAND = 'transmissions?num_rcpt_errors=3'
SPARKPOST_COMMAND_URL = "#{SPARKPOST_API}/#{SPARKPOST_NAMESPACE}/#{SPARKPOST_COMMAND}"

RECIPIENT_LIST_ERRORS = [5000, 5999]
MESSAGE_GENERATION_ERRORS = [1900, 1999]

isError = (errors = [], range = []) ->
  [left, right] = range
  errors.some (error) ->
    left <= +error.code <= right or left <= error.code <= right
module.exports = (FoxxMC)->
  FoxxMC::Utils.sendEmail = (params = {}) ->
    do (
      {
        to
        subject
        text
        html
        sendBcc = yes
      } = params
    ) ->
      unless to? and subject? and text?
        throw new Error 'Email receiver, subject and content should be specified'
      _text = text
      _html = html ? """
      <html style="font-family: arial, sans-serif;">
        <body style="font-family: arial, sans-serif;">
          <pre style="font-family: arial, sans-serif;">
          #{_text}
          </pre>
        </body>
      </html>
      """
      recipients = [
        address: to
      ]

      #   address:
      #     email: "cc@thatperson.com"
      #     header_to: "to@thisperson.com"
      if sendBcc
        recipients.push
          address:
            email: mailBcc
            header_to: to

      payload =
        recipients: recipients
        content:
          from:
            email: mailFrom
            name: mailTitle
          # headers:
          #   CC: "cc@thatperson.com"

          subject: subject
          text: _text
          html: _html

      response = request.post SPARKPOST_COMMAND_URL,
        body: JSON.stringify payload
        headers:
          'Accept'        : 'application/json'
          'Content-Type'  : 'application/json'
          'Authorization' : mailApikey

      if _.isEmpty response.body
        unless 200 <= response.statusCode < 300
          throw new Error "Mail server sent an empty response with HTTP status #{response.statusCode}"
      else
        response.body = JSON.parse response.body
        unless 200 <= response.statusCode < 300
          { errors = [] } = response
          errorsText = errors
            .map (error) -> "#{error.code}: #{error.message}"
            .join '; '
          throw new Error "Server returned HTTP status #{response.statusCode} with messages: #{errorsText}"

      response.body

  FoxxMC::Utils.sendEmail
