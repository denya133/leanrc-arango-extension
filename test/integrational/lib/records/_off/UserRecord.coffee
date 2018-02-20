

module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi, uuid }
  } = Module::

  class UserRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    @attribute handle: String,
      validate: ->
        joi.string().empty(null).default(uuid.v4, 'by default')
    @attribute email: String,
      validate: -> joi.string().email().required()
    @attribute emailHash: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute firstName: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute lastName: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute birthday: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute gender: String,
      validate: ->
        joi.string().empty(null).default('male', 'false by default')
    @attribute role: String,
      validate: ->
        joi.string().empty(null).default('user', '`user` by default')
    @attribute verified: Boolean,
      validate: ->
        joi.boolean().empty(null).default(no, 'unverified by default')
    @attribute verificationEmailSent: Boolean,
      validate: -> joi.boolean().empty(null).default(no, 'false by default')

    @attribute token: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute sharingToken: String,
      validate: -> joi.string().empty(null).default(null) # для того чтобы в registrationFlow == v3 использовать этот токен для подвязки парента.
    @attribute resetToken: String,
      validate: -> joi.string().empty(null).default(null) # Temporary token to allow reset password

    @attribute spaceId: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute homeTeamId: String,
      validate: -> joi.string().empty(null).default(null)
    @belongsTo image: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UploadRecord
    @attribute spaces: Array,
      validate: -> joi.array().items joi.string().empty(null).default(null)
    @belongsTo creator: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo editor: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo remover: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo owner: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord

    @computed isAdmin: Boolean,
      get: ->
        @role in ['admin']


  UserRecord.initialize()
